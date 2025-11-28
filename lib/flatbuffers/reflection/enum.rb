# Automatically generated. Don't modify manually.
#
# Red FlatBuffers version: 0.0.1
# Declared by:             //reflection.fbs
# Rooting type:            reflection.Schema (//reflection.fbs)

require "flatbuffers"
require_relative "key_value"
require_relative "type"
require_relative "enum_val"

module FlatBuffers
  module Reflection
    class Enum < ::FlatBuffers::Table
      def attributes
        field_offset = @view.unpack_virtual_offset(12)
        return nil if field_offset.zero?

        element_size = 4
        @view.unpack_vector(field_offset, element_size) do |element_offset|
          @view.unpack_table(KeyValue, element_offset)
        end
      end

      # File that this Enum is declared in.
      def declaration_file
        field_offset = @view.unpack_virtual_offset(16)
        return nil if field_offset.zero?

        @view.unpack_string(field_offset)
      end

      def documentation
        field_offset = @view.unpack_virtual_offset(14)
        return nil if field_offset.zero?

        element_size = 4
        @view.unpack_vector(field_offset, element_size) do |element_offset|
          @view.unpack_string(element_offset)
        end
      end

      def union?
        field_offset = @view.unpack_virtual_offset(8)
        return false if field_offset.zero?

        @view.unpack_bool(field_offset)
      end

      def name
        field_offset = @view.unpack_virtual_offset(4)
        return nil if field_offset.zero?

        @view.unpack_string(field_offset)
      end

      def underlying_type
        field_offset = @view.unpack_virtual_offset(10)
        return nil if field_offset.zero?

        @view.unpack_table(Type, field_offset)
      end

      def values
        field_offset = @view.unpack_virtual_offset(6)
        return nil if field_offset.zero?

        element_size = 4
        @view.unpack_vector(field_offset, element_size) do |element_offset|
          @view.unpack_table(EnumVal, element_offset)
        end
      end
    end
  end
end
