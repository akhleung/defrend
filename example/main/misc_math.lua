local M = {}

function M.clamp(value, lower, upper)
	if value < lower then
		return lower
	elseif value > upper then
		return upper
	else
		return value
	end
end

function M.sign(n)
	if n > 0 then
		return 1
	elseif n < 0 then
		return -1
	else
		return 0
	end
end

return M