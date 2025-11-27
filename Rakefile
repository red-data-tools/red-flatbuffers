# -*- ruby -*-
#
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

require "bundler/gem_helper"
require "rake/clean"

base_dir = __dir__

helper = Bundler::GemHelper.new(base_dir)
def helper.version_tag
  version
end

helper.install
spec = helper.gemspec

task default: :test

desc "Run tests"
task :test do
  cd(base_dir) do
    ruby("test/run.rb")
  end
end

namespace :reflection do
  desc "Generate reflection"
  task :generate do
    flatbuffers_repository = ENV["FLATBUFFERS_REPOSITORY"]
    if flatbuffers_repository.nil?
      raise "Specify FLATBUFFERS_REPOSITORY to use data in google/flatbuffers"
    end
    reflection_dir = File.join(flatbuffers_repository, "reflection")
    reflection_fbs = File.join(reflection_dir, "reflection.fbs")
    reflection_bfbs = File.join(reflection_dir, "reflection.bfbs")
    sh("flatc",
       "-o", reflection_dir,
       "--binary",
       "--schema",
       "--bfbs-builtins",
       "--bfbs-comments",
       reflection_fbs)
    ruby("-Ilib",
         "bin/rbflatc",
         "--output-dir", "lib/flatbuffers",
         "--outer-namespaces", "FlatBuffers",
         reflection_bfbs)
  end
end
