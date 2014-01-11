import xml.etree.ElementTree as ET;
from bs4 import BeautifulSoup;

tree = ET.parse('country_data.xml');
root = tree.getroot();

#root = ET.fromstring('<data>test</data>');
print root;
print root.tag;
print root.attrib;
for child in root:
	print child.tag, child.attrib;
	
print root[0][1].text;

for neighbor in root.iter('neighbor'):
	print neighbor.attrib;
	
for country in root.findall('country'):
	rank = country.find('rank').text;
	name = country.get('name');
	print name, rank;
	
for rank in root.iter('rank'):
	new_rank = int(rank.text) + 1;
	rank.text = str(new_rank);
	rank.set('updated', 'yes');
	
tree.write('output.xml');

for country in root.findall('country'):
	rank = int(country.find('rank').text);
	if(rank > 50):
		root.remove(country);
	tree.write('output.xml');
	
a = ET.Element('a');
b = ET.SubElement(a, 'b');
c = ET.SubElement(a, 'c');
d = ET.SubElement(c, 'd');
ET.dump(a);

print root.findall(".");
print root.findall("./country/neighbor");
print root.findall(".//year/..[@name='Singapore']");
print root.findall(".//*[@name='Singapore']/year");
print dir(root.findall(".//neighbor[2]"));
print root.findall(".//neighbor[2]")[0].attrib;

html_doc = """
<html><head><title>The Dormouse's story</title></head>
<body>
<p class="title"><b>The Dormouse's story</b></p>

<p class="story">Once upon a time there were three little sisters; and their names were
<a href="http://example.com/elsie" class="sister" id="link1">Elsie</a>,
<a href="http://example.com/lacie" class="sister" id="link2">Lacie</a> and
<a href="http://example.com/tillie" class="sister" id="link3">Tillie</a>;
and they lived at the bottom of a well.</p>

<p class="story">...</p>
"""

soup = BeautifulSoup(html_doc);
#soup = BeautifulSoup(open("index.html"));

print soup.prettify();
print soup.title;
print soup.title.name;
print soup.title.string;
print soup.title.parent.name;
print soup.p;
print soup.p['class'];
print soup.a;
print soup.find_all('a');
print soup.find(id="link3");

for link in soup.find_all('a'):
	print link.get('href');
	
print soup.get_text();