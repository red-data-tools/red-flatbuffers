# Automatically generated. Don't modify manually.
#
# Red FlatBuffers version: 0.0.1
# Declared by:             //reflection.fbs
# Rooting type:            reflection.Schema (//reflection.fbs)

require "flatbuffers"
require_relative "advanced_features"
require_relative "enum"
require_relative "schema_file"
require_relative "object"
require_relative "service"

module FlatBuffers
  module Reflection
    class Schema < ::FlatBuffers::Table
      def advanced_features
        field_offset = @view.unpack_virtual_offset(16)
        if field_offset.zero?
          enum_value = 0
        else
          enum_value = @view.unpack_ulong(field_offset)
        end
        AdvancedFeatures.try_convert(enum_value) || enum_value
      end

      def enums
        field_offset = @view.unpack_virtual_offset(6)
        return nil if field_offset.zero?

        @view.unpack_vector(field_offset, 4) do |element_offset|
          @view.unpack_table(Enum, element_offset)
        end
      end

      # All the files used in this compilation. Files are relative to where
      # flatc was invoked.
      def fbs_files
        field_offset = @view.unpack_virtual_offset(18)
        return nil if field_offset.zero?

        @view.unpack_vector(field_offset, 4) do |element_offset|
          @view.unpack_table(SchemaFile, element_offset)
        end
      end

      def file_ext
        field_offset = @view.unpack_virtual_offset(10)
        return nil if field_offset.zero?
        @view.unpack_string(field_offset)
      end

      def file_ident
        field_offset = @view.unpack_virtual_offset(8)
        return nil if field_offset.zero?
        @view.unpack_string(field_offset)
      end

      def objects
        field_offset = @view.unpack_virtual_offset(4)
        return nil if field_offset.zero?

        @view.unpack_vector(field_offset, 4) do |element_offset|
          @view.unpack_table(Object, element_offset)
        end
      end

      def root_table
        field_offset = @view.unpack_virtual_offset(12)
        return nil if field_offset.zero?
        @view.unpack_table(Object, field_offset)
      end

      def services
        field_offset = @view.unpack_virtual_offset(14)
        return nil if field_offset.zero?

        @view.unpack_vector(field_offset, 4) do |element_offset|
          @view.unpack_table(Service, element_offset)
        end
      end
    end
  end
end
