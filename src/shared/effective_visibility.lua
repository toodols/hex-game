-- this is server only but is also depended on line_of_sight.blocked which is a shared function
function effective_visibility(visibility: { contact: boolean, full: boolean, portal: boolean }?)
	return visibility and (visibility.contact or visibility.full or visibility.portal)
end

return {
	effective_visibility = effective_visibility,
}
