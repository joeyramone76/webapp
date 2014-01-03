import os;
import glob;
import sys;

def listDir(dir):
	for dirname, dirnames, filenames in os.walk(dir):
		# print path to all subdirectories first.
		for subdirname in dirnames:
			print os.path.join(dirname, subdirname);
			
		# print path to all filenames.
		for filename in filenames:
			print os.path.join(dirname, filename);
			
		# Advanced usage:
		# editing the 'dirnames' list will stop os.walk()
		if '.git' in dirnames:
			# don't go into any .git directories.
			dirnames.remove('.git');
			
def listPath():
	print os.listdir(".");
	for filename in os.listdir("."):
		print filename;
		
def globDir():
	print glob.glob('./*.*');
	
def ls(dir, hidden=False, relative=True):
	nodes = [];
	for nm in os.listdir(dir):
		if(not hidden and nm.startswith('.')):
			continue;
		if(not relative):
			nm = os.path.join(dir, nm);
		nodes.append(nm);
	nodes.sort();
	return nodes;

def find(root, files=True, dirs=False, hidden=False, relative=True, topdown=True):
	root = os.path.join(root, ''); # add slash if not there
	for parent, ldirs, lfiles in os.walk(root, topdown=topdown):
		if(relative):
			parent = parent[len(root):];# substr
		if(dirs and parent):
			yield os.path.join(parent, '');
		if(not hidden):
			lfiles = [nm for nm in lfiles if not nm.startswith('.')];
			ldirs[:] = [nm for nm in ldirs if not nm.startswith('.')]; # in place
		if(files):
			lfiles.sort();
			for nm in lfiles:
				nm = os.path.join(parent, nm);
				yield nm;
				
def test(root):
	print "* directory listing, with hidden files:";
	print ls(root, hidden=True);
	print
	print "* recursive listing, with dirs, but no hidden files:";
	for f in find(root, dirs=True):
		print f;
	print
	
_CURRENT_DIR = '.';

def rec_tree_traverse(curr_dir, indent):
	'''recurcive function to traverse the directory'''
	try:
		dfList = [os.path.join(curr_dir, f_or_d) for f_or_d in os.listdir(curr_dir)];
	except:
		print "wrong path name/directory name"
		return;
	
	for file_or_dir in dfList:
		if(os.path.isdir(file_or_dir)):
			print indent, file_or_dir, "\\";
			rec_tree_traverse(file_or_dir, indent * 2);
		
		if(os.path.isfile(file_or_dir)):
			print indent, file_or_dir;

def main():
	base_dir = _CURRENT_DIR;
	rec_tree_traverse(base_dir, " ");
	raw_input("enter any key to exit....");
			
if __name__ == "__main__":
	listDir("m.shenglong-electric.com.cn");
	#test(*sys.argv[1:]);
	#rec_tree_traverse("m.shenglong-electric.com.cn", " ");