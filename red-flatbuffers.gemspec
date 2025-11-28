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

clean_white_space = lambda do |entry|
  entry.gsub(/(\A\n+|\n+\z)/, '') + "\n"
end

require_relative "lib/flatbuffers/version"

Gem::Specification.new do |spec|
  spec.name = "red-flatbuffers"
  spec.version = FlatBuffers::VERSION
  spec.homepage = "https://github.com/red-data-tools/red-flatbuffers"
  spec.authors = ["Sutou Kouhei"]
  spec.email = ["kou@clear-code.com"]

  readme = File.read("README.md")
  readme.force_encoding("UTF-8")
  entries = readme.split(/^\#+\s(.*)$/)
  description = clean_white_space.call(entries[2])
  spec.summary, spec.description, = description.split(/\n\n+/, 3)
  spec.license = "Apache-2.0"
  spec.files = ["README.md", "#{spec.name}.gemspec"]
  spec.files += Dir.glob("lib/**/*.rb")
  spec.files += Dir.glob("doc/text/*")
  Dir.chdir("bin") do
    spec.executables = Dir.glob("*")
  end

  spec.metadata = {
    "bug_tracker_uri" => "#{spec.homepage}/issues",
    "changelog_uri" => "#{spec.homepage}/releases/tag/#{spec.version}",
    "source_code_uri" => spec.homepage,
  }
end
