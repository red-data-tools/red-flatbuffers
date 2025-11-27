# Automatically generated. Don't modify manually.
#
# Red FlatBuffers version: 0.0.1
# Declared by:             //reflection.fbs
# Rooting type:            reflection.Schema (//reflection.fbs)

require "flatbuffers"
require_relative "key_value"
require_relative "object"

module FlatBuffers
  module Reflection
    class RPCCall < ::FlatBuffers::Table
      def attributes
        field_offset = @view.unpack_virtual_offset(10)
        return nil if field_offset.zero?

        @view.unpack_vector(field_offset, 4) do |element_offset|
          @view.unpack_table(KeyValue, element_offset)
        end
      end

      def documentation
        field_offset = @view.unpack_virtual_offset(12)
        return nil if field_offset.zero?

        @view.unpack_vector(field_offset, 4) do |element_offset|
          @view.unpack_string(element_offset)
        end
      end

      def name
        field_offset = @view.unpack_virtual_offset(4)
        return nil if field_offset.zero?
        @view.unpack_string(field_offset)
      end

      def request
        field_offset = @view.unpack_virtual_offset(6)
        return nil if field_offset.zero?
        @view.unpack_table(Object, field_offset)
      end

      def response
        field_offset = @view.unpack_virtual_offset(8)
        return nil if field_offset.zero?
        @view.unpack_table(Object, field_offset)
      end
    end
  end
end
