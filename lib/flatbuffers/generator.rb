# Copyright 2025 Sutou Kouhei <kou@clear-code.com>
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require "fileutils"
require "pathname"

require_relative "reflection/schema"

module FlatBuffers
  class Generator
    def initialize(input)
      @schema = Reflection::Schema.new(input)
      @output_dir = Pathname(".")
      @outer_namespaces = nil
      @indent = +""
      @current_target = nil
      @requires = []
    end

    def output_dir=(dir)
      dir = Pathname(dir) unless dir.is_a?(Pathname)
      @output_dir = dir
    end

    def outer_namespaces=(namespaces)
      @outer_namespaces = namespaces
    end

    def generate
      generate_enums
      generate_objects
    end

    private
    def indent
      @indent << "  "
    end

    def unindent
      @indent = @indent[0..-3]
    end

    def generate_enums
      @schema.enums.each do |enum|
        code = +""
        start_code_block(enum)

        *namespaces, name = denamespace(enum.name)

        @outer_namespaces&.each do |ns|
          code << "#{@indent}module #{ns}\n"
          indent
        end
        namespaces.each do |ns|
          code << "#{@indent}module #{to_module_name(ns)}\n"
          indent
        end

        if enum.union?
          parent = "::FlatBuffers::Union"
        else
          attributes = enum.attributes
          if have_attribute?(attributes, "bit_flags")
            parent = "::FlatBuffers::Flags"
          else
            parent = "::FlatBuffers::Enum"
          end
        end

        generate_documentation(code, enum.documentation)
        code << "#{@indent}class #{to_class_name(name)} < #{parent}\n"
        indent
        enum.values.each do |value|
          generate_documentation(code, value.documentation)
          ruby_name = to_ruby_code(value.name)
          ruby_constant_name = to_constant_name(value.name)
          ruby_value = to_ruby_code(value.value)
          if enum.union?
            path, klass =
            resolve_class_name(value.union_type,
                               value.union_type.base_type,
                               namespaces,
                               always_use_absolute_class_name: true)
            # NAME = register("Name", value, "ClassName", "path")
            code << "#{@indent}#{ruby_constant_name} = register(#{ruby_name}, "
            code << "#{ruby_value}, #{to_ruby_code(klass)}, "
            code << "#{to_ruby_code(path)})\n"
          else
            # NAME = register("Name", value)
            code << "#{@indent}#{ruby_constant_name} = "
            code << "register(#{ruby_name}, #{ruby_value})\n"
          end
        end
        if enum.union?
          code << "\n"
          code << "#{@indent}private def require_table_class\n"
          code << "#{@indent}  require_relative @require_path\n"
          code << "#{@indent}end\n"
        end
        unindent
        code << "#{@indent}end\n"

        namespaces.each do |ns|
          unindent
          code << "#{@indent}end\n"
        end
        @outer_namespaces&.each do |ns|
          unindent
          code << "#{@indent}end\n"
        end
        emit_code_block(code, enum.name, enum.declaration_file)
      end
    end

    def generate_objects
      @schema.objects.each do |object|
        code = +""
        start_code_block(object)

        *namespaces, name = denamespace(object.name)

        @outer_namespaces&.each do |ns|
          code << "#{@indent}module #{ns}\n"
          indent
        end
        namespaces.each do |ns|
          code << "#{@indent}module #{to_module_name(ns)}\n"
          indent
        end

        if object.struct?
          parent = "::FlatBuffers::Struct"
        else
          parent = "::FlatBuffers::Table"
        end
        generate_documentation(code, object.documentation)
        code << "#{@indent}class #{to_class_name(name)} < #{parent}\n"
        indent

        n_processed_fields = 0
        object.fields&.each do |field|
          # Skip writing deprecated fields altogether.
          next if field.deprecated?

          method_name = to_method_name(field.name)
          type = field.type
          base_type = type.base_type

          code += "\n" if n_processed_fields > 0

          if base_type == Reflection::BaseType::BOOL
            method_name = "#{method_name}?".delete_prefix("is_")
          end
          generate_documentation(code, field.documentation)
          code += "#{@indent}def #{method_name}\n"
          indent

          ruby_field_offset = to_ruby_code(field.offset)
          field_offset_direct_code =
            "#{@indent}field_offset = #{ruby_field_offset}\n"
          field_offset_virtual_code = <<-CODE
#{@indent}field_offset = @view.unpack_virtual_offset(#{ruby_field_offset})
#{@indent}return #{to_ruby_code(default_value(field))} if field_offset.zero?
          CODE

          unpack_method_name = "@view.unpack_#{to_method_name(base_type.name)}"
          case base_type
          when Reflection::BaseType::UTYPE,
               Reflection::BaseType::BOOL,
               Reflection::BaseType::BYTE,
               Reflection::BaseType::UBYTE,
               Reflection::BaseType::SHORT,
               Reflection::BaseType::USHORT,
               Reflection::BaseType::INT,
               Reflection::BaseType::UINT,
               Reflection::BaseType::LONG,
               Reflection::BaseType::ULONG,
               Reflection::BaseType::FLOAT,
               Reflection::BaseType::DOUBLE
            if object.struct?
              code << field_offset_direct_code
              if enum_type?(type)
                code <<
                  "#{@indent}enum_value = #{unpack_method_name}(field_offset)\n"
                klass = register_requires(type, base_type, namespaces)
                code <<
                  "#{@indent}#{klass}.try_convert(enum_value) || enum_value"
              else
                code << "#{@indent}#{unpack_method_name}(field_offset)"
              end
            else
              if enum_type?(type)
                klass = register_requires(type, base_type, namespaces)
                code << <<-CODE
#{@indent}field_offset = @view.unpack_virtual_offset(#{ruby_field_offset})
#{@indent}if field_offset.zero?
#{@indent}  enum_value = #{to_ruby_code(default_value(field))}
#{@indent}else
#{@indent}  enum_value = #{unpack_method_name}(field_offset)
#{@indent}end
#{@indent}#{klass}.try_convert(enum_value) || enum_value
                CODE
              else
                code << field_offset_virtual_code
                code << "\n"
                code << "#{@indent}#{unpack_method_name}(field_offset)\n"
              end
            end
          when Reflection::BaseType::STRING
            code << field_offset_virtual_code
            code << "\n"
            code << "#{@indent}#{unpack_method_name}(field_offset)\n"
          when Reflection::BaseType::OBJ
            if object.struct?
              code << field_offset_direct_code
              klass = register_requires(type, base_type, namespaces)
              code << "#{@indent}@view.unpack_struct(#{klass}, field_offset)\n"
            else
              code << field_offset_virtual_code
              code << "\n"
              field_object = @schema.objects[type.index]
              klass = register_requires(type, base_type, namespaces)
              if field_object.struct?
                code <<
                  "#{@indent}@view.unpack_struct(#{klass}, field_offset)\n"
              else
                code << "#{@indent}@view.unpack_table(#{klass}, field_offset)\n"
              end
            end
          when Reflection::BaseType::UNION
            code << <<-CODE
#{@indent}type = #{to_method_name(field.name)}_type
#{@indent}return if type.nil?

#{field_offset_virtual_code}
#{@indent}@view.unpack_union(type.table_class, field_offset)
            CODE
          when Reflection::BaseType::ARRAY,
               Reflection::BaseType::VECTOR
            element_base_type = type.element
            element_size = type.element_size
            if element_base_type == Reflection::BaseType::OBJ
              klass = register_requires(type, element_base_type, namespaces)
              element_object = @schema.objects[type.index]
              if element_object.struct?
                unpack_element_code =
                  "@view.unpack_struct(#{klass}, element_offset)"
              else
                unpack_element_code =
                  "@view.unpack_table(#{klass}, element_offset)"
              end
            else
              unpack_method_name =
                "unpack_#{to_method_name(element_base_type.name)}"
              unpack_element_code = "@view.#{unpack_method_name}(element_offset)"
            end
            code << <<-CODE
#{field_offset_virtual_code}
#{@indent}element_size = #{to_ruby_code(element_size)}
#{@indent}@view.unpack_vector(field_offset, element_size) do |element_offset|
#{@indent}  #{unpack_element_code}
#{@indent}end
            CODE
          end
          unindent
          code << "#{@indent}end\n"

          n_processed_fields += 1
        end

        unindent
        code << "#{@indent}end\n"

        namespaces.each do
          unindent
          code << "#{@indent}end\n"
        end
        @outer_namespaces&.each do |ns|
          unindent
          code << "#{@indent}end\n"
        end

        emit_code_block(code, object.name, object.declaration_file)
      end
    end

    def generate_documentation(code, documentation)
      documentation&.each do |line|
        code << "#{@indent}\##{line}\n"
      end
    end

    def denamespace(name)
      name.split(".")
    end

    def have_attribute?(attributes, key)
      return false if attributes.nil?
      attributes.any? do |attribute|
        attribute.key == key
      end
    end

    def to_camel_case(name)
      name.split("_").collect do |component|
        component[0] = component[0].upcase
        component
      end.join
    end

    def to_snake_case(name)
      snake_case = +""
      previous_char = +""
      name.each_char do |char|
        if not snake_case.empty? and
          snake_case[-1] != "_" and
          char.downcase != char and
          previous_char.upcase != previous_char
          snake_case << "_"
        end
        snake_case << char
        previous_char = char
      end
      snake_case
    end

    def to_upper_snake_case(name)
      to_snake_case(name).upcase
    end

    def to_lower_snake_case(name)
      to_snake_case(name).downcase
    end

    def to_module_name(name)
      to_camel_case(name)
    end

    def to_class_name(name)
      to_camel_case(name)
    end

    def to_namespaced_class_name(namespaces, name)
      components = namespaces.collect {|namespace| to_module_name(namespace)}
      components << to_class_name(name)
      components.join("::")
    end

    def to_constant_name(name)
      to_upper_snake_case(name)
    end

    def to_variable_name(name)
      to_lower_snake_case(name)
    end

    def to_method_name(name)
      to_lower_snake_case(name)
    end

    def to_path(name)
      to_lower_snake_case(name)
    end

    def to_ruby_code(value)
      case value
      when String
        value.dump
      when Float
        if value.nan?
          "Float::NAN"
        elsif value.infinite?
          if value > 0
            "Float::INFINITY"
          else
            "-Float::INFINITY"
          end
        else
          value.to_s
        end
      when nil
        "nil"
      else
        value.to_s
      end
    end

    def default_value(field)
      base_type = field.type.base_type
      case base_type
      when Reflection::BaseType::FLOAT,
           Reflection::BaseType::DOUBLE
        field.default_real
      when Reflection::BaseType::BOOL
        not field.default_integer.zero?
      when Reflection::BaseType::UTYPE,
           Reflection::BaseType::BYTE,
           Reflection::BaseType::UBYTE,
           Reflection::BaseType::SHORT,
           Reflection::BaseType::USHORT,
           Reflection::BaseType::INT,
           Reflection::BaseType::UINT,
           Reflection::BaseType::LONG,
           Reflection::BaseType::ULONG
        field.default_integer
      else
        nil
      end
    end

    def scalar_type?(base_type)
      Reflection::BaseType::UTYPE.value <= base_type.value and
        base_type.value >= Reflection::BaseType::DOUBLE.value
    end

    def integer_type?(base_type)
      Reflection::BaseType::UTYPE.value <= base_type.value and
        base_type.value <= Reflection::BaseType::ULONG.value
    end

    def enum_type?(type)
      integer_type?(type.base_type) and type.index >= 0
    end

    def resolve_class_name(type,
                           base_type,
                           base_namespaces,
                           always_use_absolute_class_name: false)
      return nil if base_type == Reflection::BaseType::NONE

      if base_type == Reflection::BaseType::OBJ
        target = @schema.objects[type.index]
      else
        target = @schema.enums[type.index]
      end
      *namespaces, name = denamespace(target.name)
      if target.name == @current_target.name
        return [nil, to_class_name(name)]
      end

      absolute_namespaces = namespaces.dup
      base_namespaces.size.times do |i|
        base_namespace = base_namespaces[i]
        if namespaces.empty? or namespaces[0] != base_namespace
          i.step(base_namespaces.size - 1) do
            namespaces.unshift("..")
          end
          break
        end
        namespaces.shift
      end

      components = namespaces.collect {|namespace| to_path(namespace)}
      components << to_path(name)
      path = File.join(*components)
      in_same_namespace = (namespaces.empty? or namespaces[0] != "..")
      if !always_use_absolute_class_name and in_same_namespace
        # We can use relative hierarchy
        [path, to_namespaced_class_name(namespaces, name)]
      else
        # We need to use absolute hierarchy
        [path, "::#{to_namespaced_class_name(absolute_namespaces, name)}"]
      end
    end

    def register_requires(type, base_type, namespaces)
      path, class_name = resolve_class_name(type, base_type, namespaces)
      @requires |= [path] if path
      class_name
    end

    def start_code_block(target)
      @current_target = target
      @requires = []
    end

    def emit_code_block(code_block, name, declaration_file)
      code = +"# Automatically generated. Don't modify manually.\n"
      code << "#\n"
      code << "# Red FlatBuffers version: #{FlatBuffers::VERSION}\n"
      unless declaration_file.empty?
        code << "# Declared by:             #{declaration_file}\n"
      end
      root_table = @schema.root_table
      if root_table
        root_type = root_table.name
        root_file = root_table.declaration_file
        code << "# Rooting type:            #{root_type} (#{root_file})\n"
      end
      code << "\n"

      code << "require \"flatbuffers\"\n"
      @requires.each do |require|
        code << "require_relative \"#{require}\"\n"
      end
      code << "\n"

      code << code_block;

      output_path = @output_dir
      components = denamespace(name)
      components[0..-2].each do |component|
        output_path += to_path(component)
      end
      output_path += "#{to_path(components.last)}.rb"
      FileUtils.mkdir_p(output_path.parent.to_s)
      output_path.write(code)
    end
  end
end
