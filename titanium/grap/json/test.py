import json;
from StringIO import StringIO;
import decimal;

json.dumps(['foo', {'bar':('baz', None, 1.0, 2)}]);
print json.dumps("\"foo\bar");
print json.dumps(u'\u1234');
print json.dumps('\\');
print json.dumps({"c":0,"b":0,"a":0}, sort_keys=True);
io = StringIO();
json.dump(['streaming API'], io);
print io.getvalue();

print json.dumps([1,2,3,{'4':5,'6':7}], separators=(',',':'));

print json.dumps({'4':5,'6':7}, sort_keys=True, indent=4, separators=(',',': '));

print json.loads('["foo", {"bar":["baz", null, 1.0, 2]}]');
print json.loads('"\\"foo\\bar"');
io = StringIO('["streaming API"]');
print json.load(io);

def as_complex(dct):
	if '__complex__' in dct:
		return complex(dct['real'], dct['imag']);
	return dct;

#string
#['__add__', '__class__', '__contains__', '__delattr__', '__doc__', '__eq__', '__format__',
#'__ge__', '__getattribute__', '__getitem__', '__getnewargs__', '__getslice__',
#'__gt__', '__hash__', '__init__', '__le__', '__len__', '__lt__', '__mod__',
#'__mul__', '__ne__', '__new__', '__reduce__', '__reduce_ex__', '__repr__',
#'__rmod__', '__rmul__', '__setattr__', '__sizeof__', '__str__', '__subclasshook__',
#'_formatter_field_name_split', '_formatter_parser', 'capitalize', 'center',
#'count', 'decode', 'encode', 'endswith', 'expandtabs', 'find', 'format', 'index',
#'isalnum', 'isalpha', 'isdecimal', 'isdigit', 'islower', 'isnumeric', 'isspace',
#'istitle', 'isupper', 'join', 'ljust', 'lower', 'lstrip', 'partition', 'replace',
#'rfind', 'rindex', 'rjust', 'rpartition', 'rsplit', 'rstrip', 'split', 'splitlines',
#'startswith', 'strip', 'swapcase', 'title', 'translate', 'upper', 'zfill']
print json.loads('{"__complex__": true, "real": 1, "imag": 2}', object_hook=as_complex);
print json.loads('1.1', parse_float=decimal.Decimal);

class ComplexEncoder(json.JSONEncoder):
	def default(self, obj):
		if(isinstance(obj, complex)):
			return [obj.real, obj.imag];
		return json.JSONEncoder.default(self, obj);
print json.dumps(2 + 1j, cls=ComplexEncoder);

print ComplexEncoder().encode(2 + 1j);
print list(ComplexEncoder().iterencode(2 + 1j));

#Python	JSON
#dict	object
#list, tuple	array
#str, unicode	string
#int, long, float	number
#True	true
#False	false
#None	null