#!/usr/bin/ruby

require 'rubyscape'

#
# A class to create overlays by showing and hiding elements of an SVG file 
# and taking snapshots. To implement a new overlay, simply extend this class
# and override the script method.
#
class SimpleOverlay < RubyScape
	
	# Data
	attr_accessor :count, :last
	
	# Counters for latex generation
	attr_accessor :latex_count, :latex_file_count
	
	# Options
	attr_accessor :cleanup, :eps, :quiet, :wait, :inkscape
		
	#
	# Creates a new simple overlay that will animate the SVG in this file
	#
	def initialize(file)
		super(file)
		@count = 1
		@latex_count = 1
		@latex_file_count = 1
		@cleanup = 1
		@eps = 1
		@quiet = false
		@wait = -1
		@inkscape="/usr/bin/inkscape"
		script()
	end
	
	#
	# This causes the overlay to wait until this index to start producing
	# snapshots. The modifications are stil performed to the document, but
	# snapshots are skipped. This is very useful at development time because
	# EPS generation is very time consuming
	#
	def wait_until(index)
		@wait = index
	end
	
	#
	# Shows the layer with this label, storing it at the "last layer" register
	#
	def showL(layer_label)
		@last = getLayer(layer_label)
		showLayer(@last)
	end
	
	#
	# Hides the layer with this label
	#
	def hideL(layer_label)
		hideLayer(getLayer(layer_label))
	end
	
	#
	# Swaps the "last layer shown" with the layer that has this label.
	#
	def swapL(layer_label)
		hideLayer(@last)
		showL(layer_label)
	end
	
	#
	# Takes a snapshot of the current state of the SVG document and stores
	# in a numbered EPS file. The current state is also saved as an SVG file,
	# but it will be deleted if cleanup is set.
	#
	def snapshot()
		if(@wait != -1 && @count < @wait)
			@count += 1
			return
		end
		
		if (! @quiet)
			puts "Snapshot ##{@count}"
		end
		
		newName = File.basename(@file.path, ".svg") + "#{@count}"
		@count += 1
		
		## Save a new SVG file
		save(newName + ".svg")
		
		## Convert to EPS
		if (@eps)
			system("#{@inkscape} -E=#{newName}.eps #{newName}.svg -z -d=90 -C --export-ignore-filters 2>/dev/null")
		end
		
		## Delete the SVG file
		if (@cleanup)
			File.delete(newName + ".svg")
		end
	end
	
	#
	# Generates a numbered latex file which contains insertions for each 
	# generated EPS file so far.
	#
	# title:: a string for the title of the slides
	# basedir:: an optional string for the directory name of the eps files
	#
	def latex(title, basedir = "")
		# Open the file to write
		baseName = File.basename(@file.path, ".svg")
		file = File.new(baseName  + "#{@latex_file_count}" + ".tex", "w")
		
		# Print the 
		(@latex_count..@count - 1).each do |i|
			file.puts("\\begin{slide}{#{title}}\n" +
					  "  \\centering\n" +
                      "  \\includegraphics[]{" + basedir + baseName + "#{i}}\n" +
                      "\\end{slide}\n\n")
		end
		
		# Finalize
		@latex_count = @count
		@latex_file_count += 1
		file.close
	end
	
	#
	# Subclasses should implement this method to script the animation.
	#
	def script
		puts "You should extend script()"
	end
end
