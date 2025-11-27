# Automatically generated. Don't modify manually.
#
# Red FlatBuffers version: 0.0.1
# Declared by:             //reflection.fbs
# Rooting type:            reflection.Schema (//reflection.fbs)

require "flatbuffers"
require_relative "key_value"
require_relative "field"

module FlatBuffers
  module Reflection
    class Object < ::FlatBuffers::Table
      def attributes
        field_offset = @view.unpack_virtual_offset(14)
        return nil if field_offset.zero?

        @view.unpack_vector(field_offset, 4) do |element_offset|
          @view.unpack_table(KeyValue, element_offset)
        end
      end

      def bytesize
        field_offset = @view.unpack_virtual_offset(12)
        return 0 if field_offset.zero?

        @view.unpack_int(field_offset)
      end

      # File that this Object is declared in.
      def declaration_file
        field_offset = @view.unpack_virtual_offset(18)
        return nil if field_offset.zero?

        @view.unpack_string(field_offset)
      end

      def documentation
        field_offset = @view.unpack_virtual_offset(16)
        return nil if field_offset.zero?

        @view.unpack_vector(field_offset, 4) do |element_offset|
          @view.unpack_string(element_offset)
        end
      end

      def fields
        field_offset = @view.unpack_virtual_offset(6)
        return nil if field_offset.zero?

        @view.unpack_vector(field_offset, 4) do |element_offset|
          @view.unpack_table(Field, element_offset)
        end
      end

      def struct?
        field_offset = @view.unpack_virtual_offset(8)
        return false if field_offset.zero?

        @view.unpack_bool(field_offset)
      end

      def minalign
        field_offset = @view.unpack_virtual_offset(10)
        return 0 if field_offset.zero?

        @view.unpack_int(field_offset)
      end

      def name
        field_offset = @view.unpack_virtual_offset(4)
        return nil if field_offset.zero?

        @view.unpack_string(field_offset)
      end
    end
  end
end
