import os;
import string;

class Base:
	'''Represents base.'''
	def __init__(self, dirPath, suffix):
		self.dirPath = dirPath;
		self.suffix = suffix;
		print '(Initialized Base: %s)' % self.dirPath
		
	def getDirPath(self):
		'''get dirPath.'''
		print 'dirPath:"%s"' % (self.dirPath);

class SearchFile(Base):
	def __init__(self, dirPath, suffix):
		Base.__init__(self, dirPath, suffix);
	def __del__(self):
		print 'release object';
	def getAllFiles(self):
		print 'getAllFiles';
		files = [];
		for dirname, dirnames, filenames in os.walk(self.dirPath):
			for filename in filenames:
				if(string.find(filename, ".html") >= 0):
					files.append(os.path.join(dirname, filename));
		return files;
	def sayHi(self):
		print 'Hello World!';

version = '0.1';

if __name__ == '__main__':
	print 'This program is being run by itself';
else:
	print 'I am being imported from another module';