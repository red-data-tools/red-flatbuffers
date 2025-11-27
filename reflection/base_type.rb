# Automatically generated. Don't modify manually.
#
# Red FlatBuffers version: 0.0.1
# Declared by:             //reflection.fbs
# Rooting type:            reflection.Schema (//reflection.fbs)

require "flatbuffers"

module FlatBuffers
  module Reflection
    class BaseType < ::FlatBuffers::Enum
      NONE = register("None", 0)
      UTYPE = register("UType", 1)
      BOOL = register("Bool", 2)
      BYTE = register("Byte", 3)
      UBYTE = register("UByte", 4)
      SHORT = register("Short", 5)
      USHORT = register("UShort", 6)
      INT = register("Int", 7)
      UINT = register("UInt", 8)
      LONG = register("Long", 9)
      ULONG = register("ULong", 10)
      FLOAT = register("Float", 11)
      DOUBLE = register("Double", 12)
      STRING = register("String", 13)
      VECTOR = register("Vector", 14)
      OBJ = register("Obj", 15)
      UNION = register("Union", 16)
      ARRAY = register("Array", 17)
      VECTOR64 = register("Vector64", 18)
      MAX_BASE_TYPE = register("MaxBaseType", 19)
    end
  end
end
