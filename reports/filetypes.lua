--[[
	Generates a histogram visualizing type file type distribution
--]]


-- Script meta-data
meta.title = "File types histogram"
meta.description = "Histogram of the file types distribution"
meta.options = {{"-rARG, --revision=ARG", "Select revision (defaults to HEAD)"},
                {"-nARG", "Show the ARG most frequent file types"}}

require "pepper.plotutils"
pepper.plotutils.add_plot_options()


-- Maps file extensions to languages
extmap = {
	[".h"] = "C/C++",
	[".hxx"] = "C/C++",
	[".hpp"] = "C/C++",
	[".c"] = "C/C++",
	[".cc"] = "C/C++",
	[".cxx"] = "C/C++",
	[".cpp"] = "C/C++",
	[".txx"] = "C/C++",
	[".java"] = "Java",
	[".lua"] = "Lua",
	[".s"] = "Assembler",
	[".pl"] = "Perl",
	[".pm"] = "Perl",
	[".sh"] = "Shell",
	[".py"] = "Python",
	[".txt"] = "Text",
	[".po"] = "Gettext",
	[".m4"] = "Autotools",
	[".at"] = "Autotools",
	[".ac"] = "Autotools",
	[".am"] = "Autotools",
	[".htm"] = "HTML",
	[".html"] = "HTML",
	[".xhtml"] = "HTML",
	[".bat"] = "Batch",
	[".cs"] = "C#",
	[".hs"] = "Haskell",
	[".lhs"] = "Haskell",
	[".js"] = "JavaScript",
	[".php"] = "PHP",
	[".php4"] = "PHP",
	[".php5"] = "PHP",
	[".scm"] = "Scheme",
	[".ss"] = "Scheme",
	[".vb"] = "Visual Basic",
	[".vbs"] = "Visual Basic",
	[".go"] = "Go"
}

-- Returns the extension of a file
function extension(filename)
	local file,n = string.gsub(filename, "(.*/)(.*)", "%2")
	local ext,n = string.gsub(file, ".*(%..+)", "%1")
	if #ext == #file then
		return nil
	end
	return string.lower(ext)
end 

-- Compares two {name, value} pairs
function countcmp(a, b)
	if a[1] == "unknown" then
		return false
	end
	if b[1] == "unknown" then
		return true
	end
	return (a[2] > b[2])
end

-- Main report function
function main()
	local rev = pepper.report.getopt("r, revision", "")
	local tree = pepper.report.repository():tree(rev)

	-- For now, simply count the number of files for each extension
	local count = {}
	for i,v in ipairs(tree) do
		local ext = extension(v)
		local nam = ""
		if ext ~= nil then
			nam = extmap[ext]
			if nam == nil then
				nam = string.upper(ext:sub(2))
			end
		else
			nam = "unknown"
		end
		if count[nam] == nil then
			count[nam] = 0
		end
		count[nam] = count[nam] + 1
	end

	-- Sort by number of files
	local extcount = {}
	for k,v in pairs(count) do
		table.insert(extcount, {k, v})
	end
	table.sort(extcount, countcmp)

	-- Use descriptive titles
	local keys = {}
	local values = {}
	local n = 1 + tonumber(pepper.report.getopt("n", 6))
	for i,v in pairs(extcount) do
		if i > n then
			break
		end
		if v[1] ~= "unknown" then
			table.insert(keys, v[1])
			table.insert(values, v[2])
		end
	end
	
	if count["unknown"] ~= nil then
		table.insert(keys, "unknown")
		table.insert(values, count["unknown"])
	end

	local p = pepper.gnuplot:new()
	pepper.plotutils.setup_output(p, 600, 300)
	if #rev > 0 then
		p:set_title("File types (at " .. rev .. ")")
	else
		p:set_title("File types")
	end

	p:cmd([[
set style fill solid border -1
set style histogram cluster gap 1
set xtics nomirror
set ylabel "Number of files"
]])
	p:plot_histogram(keys, values)
end