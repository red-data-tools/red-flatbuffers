# Automatically generated. Don't modify manually.
#
# Red FlatBuffers version: 0.0.1
# Declared by:             //reflection.fbs
# Rooting type:            reflection.Schema (//reflection.fbs)

require "flatbuffers"

module FlatBuffers
  module Reflection
    # New schema language features that are not supported by old code generators.
    class AdvancedFeatures < ::FlatBuffers::Flags
      ADVANCED_ARRAY_FEATURES = register("AdvancedArrayFeatures", 1)
      ADVANCED_UNION_FEATURES = register("AdvancedUnionFeatures", 2)
      OPTIONAL_SCALARS = register("OptionalScalars", 4)
      DEFAULT_VECTORS_AND_STRINGS = register("DefaultVectorsAndStrings", 8)
    end
  end
end
