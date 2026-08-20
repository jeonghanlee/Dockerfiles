#!/usr/bin/env ruby

require "open3"
require "pathname"
require "uri"

ROOT = Pathname.new(__dir__).realpath
INLINE_LINK = /!?\[[^\]]*\]\(([^)]+)\)/
REFERENCE_LINK = /^\s{0,3}\[[^\]]+\]:\s*(\S+)/
EXTERNAL_TARGET = %r{\A(?:[a-z][a-z0-9+.-]*:|//|/)}i

def markdown_files
  output, status = Open3.capture2(
    "git", "-C", ROOT.to_s, "ls-files", "--cached", "--others",
    "--exclude-standard", "--", "*.md"
  )
  abort "error: unable to enumerate Markdown files" unless status.success?

  output.lines
    .map { |line| Pathname.new(line.chomp) }
    .reject(&:empty?)
    .select { |path| (ROOT / path).file? }
end

def link_target(raw_target)
  target = raw_target.strip
  return "" if target.empty?

  if target.start_with?("<") && target.include?(">")
    target[1...target.index(">")]
  else
    target.split(/\s+/, 2).first
  end
end

def local_target(source, target)
  return if target.empty? || target.start_with?("#") || target.match?(EXTERNAL_TARGET)

  path = target.split(/[?#]/, 2).first
  return if path.empty?

  decoded = URI::DEFAULT_PARSER.unescape(path)
  (ROOT / source.dirname / decoded).cleanpath
rescue URI::InvalidURIError
  nil
end

def fenced_line?(line, fence)
  marker = line.lstrip[/\A(`{3,}|~{3,})/, 1]
  return [false, fence] unless marker

  if fence
    [marker.start_with?(fence[0]) && marker.length >= fence.length, nil]
  else
    [true, marker]
  end
end

errors = []

markdown_files.each do |source|
  fence = nil

  (ROOT / source).each_line.with_index(1) do |line, line_number|
    toggled, next_fence = fenced_line?(line, fence)
    if toggled
      fence = next_fence
      next
    end
    next if fence

    scan_line = line.gsub(/`[^`]*`/, "")
    targets = scan_line.scan(INLINE_LINK).flatten
    reference = scan_line.match(REFERENCE_LINK)
    targets << reference[1] if reference

    targets.each do |raw_target|
      target = link_target(raw_target)
      candidate = local_target(source, target)
      next unless candidate

      unless candidate.to_s == ROOT.to_s || candidate.to_s.start_with?("#{ROOT}/")
        errors << "#{source}:#{line_number}: local link leaves repository: #{target}"
        next
      end

      next if candidate.exist?

      errors << "#{source}:#{line_number}: missing local link target: #{target}"
    end
  end
end

if errors.empty?
  puts "Markdown local links: OK"
  exit 0
end

warn errors.join("\n")
exit 1
