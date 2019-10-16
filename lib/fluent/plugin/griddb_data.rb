#!/usr/bin/env ruby

$: .unshift File.dirname(__FILE__)

module Fluent
	module GridDBData
		# Format for chunk data
		def chunk_convert(chunk)
			arrays_2 = Array.new
			tmp = Array.new
			chunk.msgpack_each do |time, record|
				tmp = hash_to_array(record)
				arrays_2.push(tmp)
			end			
			arrays_2
		end
	
		#Format for each record
		def convert(record)
			arrays_2 = Array.new
			tmp = hash_to_array(record)
			arrays_2.push(tmp)
		end

		# Covert from hash object to array
		def hash_to_array(record)
			arr = Array.new
			record.map do |key, val |
				arr.push(val)
			end			
			arr
		end

	end
end