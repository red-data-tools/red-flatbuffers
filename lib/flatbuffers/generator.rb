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
    module NameConvertable
      private
      def denamespace(name)
        name.split(".")
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
    end

    include NameConvertable

    class Writer
      include NameConvertable

      def initialize(schema, target)
        @schema = schema
        @target = target
        @indent = +""
        @requires = []
      end

      def add_require(path)
        @requires |= [path]
      end

      def start(output_dir)
        output_path = output_dir
        components = denamespace(@target.name)
        components[0..-2].each do |component|
          output_path += to_path(component)
        end
        output_path += "#{to_path(components.last)}.rb"
        FileUtils.mkdir_p(output_path.parent.to_s)
        output_path.open("w") do |output|
          @output = output
          write_header
          yield
          @output = nil
        end
      end

      def indent
        @indent << "  "
      end

      def unindent
        @indent = @indent[0..-3]
      end

      def <<(line)
        if line.empty?
          @output << "\n"
        else
          @output << @indent << line << "\n"
        end
      end

      def end
        unindent
        self << "end"
      end

      private
      def write_header
        self << "# Automatically generated. Don't modify manually."
        self << "#"
        self << "# Red FlatBuffers version: #{FlatBuffers::VERSION}"
        declaration_file = @target.declaration_file
        unless declaration_file.empty?
          self << "# Declared by:             #{declaration_file}"
        end
        root_table = @schema.root_table
        if root_table
          root_type = root_table.name
          root_file = root_table.declaration_file
          self << "# Rooting type:            #{root_type} (#{root_file})"
        end
        self << ""
        self << "require \"flatbuffers\""
        @requires.each do |require|
          self << "require_relative \"#{require}\""
        end
        self << ""
      end
    end

    def initialize(input)
      @schema = Reflection::Schema.new(input)
      self.output_dir = Pathname(".")
      self.outer_namespaces = nil
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
    def generate_enums
      @schema.enums.each do |enum|
        writer = Writer.new(@schema, enum)
        writer.start(@output_dir) do
          generate_enum(writer, enum)
        end
      end
    end

    def start_modules(writer, namespaces)
      @outer_namespaces&.each do |ns|
        writer << "module #{ns}"
        writer.indent
      end
      namespaces.each do |ns|
        writer << "module #{to_module_name(ns)}"
        writer.indent
      end
    end

    def end_modules(writer, namespaces)
      namespaces.each do |ns|
        writer.end
      end
      @outer_namespaces&.each do |ns|
        writer.end
      end
    end

    def generate_enum(writer, enum)
      *namespaces, name = denamespace(enum.name)

      start_modules(writer, namespaces)

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

      generate_documentation(writer, enum.documentation)
      writer << "class #{to_class_name(name)} < #{parent}"
      writer.indent
      enum.values.each do |value|
        generate_documentation(writer, value.documentation)
        ruby_name = to_ruby_code(value.name)
        ruby_constant_name = to_constant_name(value.name)
        ruby_value = to_ruby_code(value.value)
        if enum.union?
          union = @schema.objects[value.union_type.index]
          *union_namespaces, union_name = denamespace(union.name)
          klass = "::#{to_namespaced_class_name(union_namespaces, union_name)}"
          relative_union_namespaces =
            resolve_namespaces(union_namespaces, namespaces)
          path_components = relative_union_namespaces.collect do |ns|
            to_path(ns)
          end
          path_components << to_path(union_name)
          path = File.join(*path_components)
          # NAME = register("Name", value, "ClassName", "path")
          writer << ("#{ruby_constant_name} = register(" +
                     "#{ruby_name}, " +
                     "#{ruby_value}, " +
                     "#{to_ruby_code(klass)}, " +
                     "#{to_ruby_code(path)})")
        else
          # NAME = register("Name", value)
          writer << ("#{ruby_constant_name} = " +
                     "register(#{ruby_name}, #{ruby_value})")
        end
      end
      if enum.union?
        writer << "\n"
        writer << "private def require_table_class"
        writer.indent
        writer << "require_relative @require_path"
        writer.end
      end
      writer.end

      end_modules(writer, namespaces)
    end

    def generate_objects
      @schema.objects.each do |object|
        writer = Writer.new(@schema, object)
        detect_object_dependencies(writer, object)
        writer.start(@output_dir) do
          generate_object(writer, object)
        end
      end
    end

    def detect_object_dependencies(writer, object)
      *base_namespaces, _name = denamespace(object.name)
      object.fields&.each do |field|
        next if field.deprecated?

        type = field.type
        base_type = type.base_type
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
             Reflection::BaseType::ULONG
          next if type.index < 0
          target = @schema.enums[type.index]
        when  Reflection::BaseType::OBJ
          target = @schema.objects[type.index]
          next if target.name == object.name
        when Reflection::BaseType::ARRAY,
             Reflection::BaseType::VECTOR
          element_base_type = type.element
          next unless element_base_type == Reflection::BaseType::OBJ
          target = @schema.objects[type.index]
          next if target.name == object.name
        else
          next
        end

        *namespaces, name = denamespace(target.name)
        relative_namespaces = resolve_namespaces(namespaces, base_namespaces)
        components = relative_namespaces.collect {|ns| to_path(ns)}
        components << to_path(name)
        path = File.join(*components)
        writer.add_require(path)
      end
    end

    def generate_object(writer, object)
      *namespaces, name = denamespace(object.name)

      start_modules(writer, namespaces)

      if object.struct?
        parent = "::FlatBuffers::Struct"
      else
        parent = "::FlatBuffers::Table"
      end
      generate_documentation(writer, object.documentation)
      writer << "class #{to_class_name(name)} < #{parent}"
      writer.indent

      n_processed_fields = 0
      object.fields&.each do |field|
        # Skip writing deprecated fields altogether.
        next if field.deprecated?

        writer << "" if n_processed_fields > 0

        method_name = to_method_name(field.name)
        type = field.type
        base_type = type.base_type
        if base_type == Reflection::BaseType::BOOL
          method_name = "#{method_name}?".delete_prefix("is_")
        end
        generate_documentation(writer, field.documentation)
        writer << "def #{method_name}"
        writer.indent

        ruby_field_offset = to_ruby_code(field.offset)
        field_offset_direct_code = "field_offset = #{ruby_field_offset}"
        field_offset_virtual_code =
          "field_offset = @view.unpack_virtual_offset(#{ruby_field_offset})"
        return_default_virtual_code =
          "return #{to_ruby_code(default_value(field))} if field_offset.zero?"
        unpack_method = "@view.unpack_#{to_method_name(base_type.name)}"

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
            writer << field_offset_direct_code
            if enum_type?(type)
              writer << "enum_value = #{unpack_method}(field_offset)"
              klass = resolve_class_name(type, base_type, namespaces)
              writer << "#{klass}.try_convert(enum_value) || enum_value"
            else
              writer << "#{unpack_method}(field_offset)"
            end
          else
            writer << field_offset_virtual_code
            if enum_type?(type)
              klass = resolve_class_name(type, base_type, namespaces)
              writer << "if field_offset.zero?"
              writer.indent
              writer << "enum_value = #{to_ruby_code(default_value(field))}"
              writer.unindent
              writer << "else"
              writer.indent
              writer << "enum_value = #{unpack_method}(field_offset)"
              writer.end
              writer << "#{klass}.try_convert(enum_value) || enum_value"
            else
              writer << return_default_virtual_code
              writer << ""
              writer << "#{unpack_method}(field_offset)"
            end
          end
        when Reflection::BaseType::STRING
          writer << field_offset_virtual_code
          writer << return_default_virtual_code
          writer << ""
          writer << "#{unpack_method}(field_offset)"
        when Reflection::BaseType::OBJ
          if object.struct?
            writer << field_offset_direct_code
            klass = resolve_class_name(type, base_type, namespaces)
            writer << "@view.unpack_struct(#{klass}, field_offset)\n"
          else
            writer << field_offset_virtual_code
            writer << return_default_virtual_code
            writer << ""
            field_object = @schema.objects[type.index]
            klass = resolve_class_name(type, base_type, namespaces)
            if field_object.struct?
              writer << "@view.unpack_struct(#{klass}, field_offset)"
            else
              writer << "@view.unpack_table(#{klass}, field_offset)"
            end
          end
        when Reflection::BaseType::UNION
          writer << "type = #{to_method_name(field.name)}_type"
          writer << "return nil if type.nil?"
          writer << ""
          writer << field_offset_virtual_code
          writer << return_default_virtual_code
          writer << "@view.unpack_union(type.table_class, field_offset)"
        when Reflection::BaseType::ARRAY,
             Reflection::BaseType::VECTOR
          element_base_type = type.element
          element_size = type.element_size
          if element_base_type == Reflection::BaseType::OBJ
            klass = resolve_class_name(type, element_base_type, namespaces)
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
          writer << field_offset_virtual_code
          writer << return_default_virtual_code
          writer << ""
          writer << "element_size = #{to_ruby_code(element_size)}"
          writer <<
            "@view.unpack_vector(field_offset, element_size) do |element_offset|"
          writer.indent
          writer << unpack_element_code
          writer.end
        end
        writer.end

        n_processed_fields += 1
      end

      writer.end # class

      end_modules(writer, namespaces)
    end

    def generate_documentation(writer, documentation)
      documentation&.each do |line|
        writer << "\##{line}"
      end
    end

    def have_attribute?(attributes, key)
      return false if attributes.nil?
      attributes.any? do |attribute|
        attribute.key == key
      end
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

    def resolve_namespaces(namespaces, base_namespaces)
      resolved_namespaces = namespaces.dup
      base_namespaces.size.times do |i|
        base_namespace = base_namespaces[i]
        if namespaces.empty? or namespaces[0] != base_namespace
          i.step(base_namespaces.size - 1) do
            resolved_namespaces.unshift("..")
          end
          break
        end
        resolved_namespaces.shift
      end
      resolved_namespaces
    end

    def resolve_class_name(type,
                           base_type,
                           base_namespaces)
      if base_type == Reflection::BaseType::OBJ
        target = @schema.objects[type.index]
      else
        target = @schema.enums[type.index]
      end
      *namespaces, name = denamespace(target.name)
      relative_namespaces = resolve_namespaces(namespaces, base_namespaces)
      in_same_namespace =
        (relative_namespaces.empty? or relative_namespaces[0] != "..")
      if in_same_namespace
        # We can use relative hierarchy
        to_namespaced_class_name(relative_namespaces, name)
      else
        # We need to use absolute hierarchy
        "::#{to_namespaced_class_name(namespaces, name)}"
      end
    end
  end
end
