/// array_literal(...values)
var l_i = argument_count;
var l_result = array_create(l_i);
while (--l_i >= 0) l_result[l_i] = argument[l_i];
return l_result;