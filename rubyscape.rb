#!/usr/bin/ruby

require 'hpricot'
require 'ftools'

#
# A simple API for manipulating Inkscape SVG files.
#
class RubyScape

	DISPLAY='display'
	INLINE='inline'
	NONE='none'
	
	attr_accessor :doc, :file
	
	#
	# Creates a new RubyScape object representing this SVG file.
	# 
	# This method will already parse the file and store it in the doc 
	# attribute.
	#
	def initialize(file)
		@file = file
		@doc = Hpricot.XML(file)
	end
	
	#
	# Save the current state of the document in a file with this name.
	#
	def save(file_name)
		svg = File.new(file_name, "w")
		svg.puts(doc.to_html)
		svg.close
	end
	
	## Methods to search elements in the SVG image
	
	#
	# Gets the layer indicated by this label or nil
	#
	def getLayer(layer_label)
		# this code is ugly because @inkscape:label does not work, I think because of the :
		(doc/"svg/g").each do |layer|
			if(layer['inkscape:label'] == layer_label)
				return layer
			end
		end
		puts "Could not find layer with label = #{layer_label}"
		return nil
	end
	
	#
	# Gets the object with this id. The object can be a group, path, text
	# or whatever else SVG files contain.
	#
	def getObject(id)
		doc.search("[@id='#{id}']").first
	end
	
	#
	# Gets the path with this id.
	#
	def getPath(path_id)
		doc.search("path[@id='#{path_id}']").first
	end
	
	#
	# Gets the text with this id.
	#
	def getText(text_id)
		doc.search("text[@id='#{text_id}']").first
	end

	## Methods to modify elements in the SVG image
	
	#
	# Makes this layer visible. You should pass a reference to a layer
	# element, probably obtained with getLayer().
	#
	def showLayer(layer)
		layer['style'] = setting(DISPLAY, INLINE)
	end
	
	#
	# Makes this layer invisible. You should pass a reference to a layer
	# element, probably obtained with getLayer().
	#
	def hideLayer(layer)
		layer['style'] = setting(DISPLAY, NONE)
	end
	
	#
	# Makes the object with this id visible. If the object is not found,
	# a warning is printed.
	#
	def show(id)
		set_attribute_property(id, 'style', DISPLAY, INLINE)
	end
	
	#
	# Makes the object with this id invisible. If the object is not found,
	# a warning is printed.
	#
	def hide(id)
		set_attribute_property(id, 'style', DISPLAY, NONE)
	end
		
	#
	# Manipulates the style attribute of the object with this id. This method
	# will set the 'property' of the 'style' to this 'value', overridding any
	# pre-existing values. A warning is printed if the object is not found.
	#
	def set_style_prop(id, property, value)
		set_attribute_property(id, 'style', property, value)
	end
	
	#
	# Updates the property of this attribute of the object with this id, to this value.
	#
	# First id is used to find an object and attribute to find an attribute of the object.
	# The attribute will be rewritten to contain a property:value pair according to the
	# arguments.
	#
	def set_attribute_property(id, attribute, property, value)
		o = getObject(id)
		if (o != nil && o.respond_to?(:[]))
			if (o[attribute] != nil)
				if (o[attribute].include?(property))
					o[attribute] = o[attribute].gsub(/#{property}\:.*(\;|$)/, setting(property, value))
				else
					s = o[attribute]
					if (s[-1, 1] != ';') 
						s += ';'
					end
					o[attribute] = s + setting(property, value)
				end
			else
				o[attribute] = setting(property, value)
			end
		else
			puts "Could not find object with id = #{id}"
		end
	end
	
	#
	# Sets the attribute of the object with this id to this value.
	#
	def set_attribute(id, attribute, value)
		o = getObject(id)
		if (o != nil && o.respond_to?(:[]))
			o[attribute] = value
		else
			puts "Could not find object with id = #{id}"
		end
	end
	
	## Helpers
	
	#
	# Returns the string representing the setting of this property to this value.
	#
	def setting(property, value)
		property + ':' + value + ';'
	end
end



