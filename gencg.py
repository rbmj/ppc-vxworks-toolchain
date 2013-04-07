import sys
import os
import hashlib
import uuid

cg_name = sys.argv[1]
#handle different kinds of escaping
search_root = sys.argv[2].replace("\\\\", "\\")

root_path = os.path.dirname(search_root)
dirlist = dict()
filelist = dict()

def stripPrefix(dir):
	return dir[len(root_path):]

def getDirID(dir):
	m = hashlib.md5()
	m.update(dir.encode('utf-8'))
	return "dir" + cg_name + m.hexdigest() + str(len(dir))

def getFileID(f, dir):
	m = hashlib.md5()
	m.update(dir.encode('utf-8')) # need a bit more entropy...
	m.update(f.encode('utf-8'))
	return cg_name + m.hexdigest() + str(len(f))

root_id = getDirID(search_root)

def addDir(dir):
	if dir == search_root:
		return root_id
	dirID = getDirID(dir)
	if dirID in dirlist:
		return dirID
	pdirname = os.path.dirname(dir)
	pdir_id = getDirID(pdirname)
	if pdirname != search_root:
		if pdir_id not in dirlist:
			addDir(pdirname)
	dirname = os.path.basename(dir)
	dirlist[dirID] = (dirID, pdir_id, dirname)
	return dirID
	
def addFile(dir, fname):
	parent_id = addDir(dir)
	file_id = getFileID(fname, dir)
	dir = dir.replace("/", "\\") # in case we're on unix
	filelist[file_id] = (file_id, parent_id, "SourceDir\\" + dir + '\\' + fname)

for root, dirs, files in os.walk(search_root):
	for file in files:
		addFile(root, file)

#header
print('<?xml version="1.0" encoding="utf-8"?>')
print('<Wix xmlns="http://schemas.microsoft.com/wix/2006/wi">')

#root fragment
print('\t<Fragment>')
print('\t\t<DirectoryRef Id="INSTALLDIR">')
print('\t\t\t<Directory Id="' + root_id + '" Name="' + os.path.basename(search_root) + '" />')
print('\t\t</DirectoryRef>')
print('\t</Fragment>')

#components
print('\t<Fragment>')
print('\t\t<ComponentGroup Id="' + cg_name + '">')
for cmp_id, dir_id, source in filelist.values():
	#generate a uuid:
	guid = uuid.uuid5(uuid.NAMESPACE_URL, 'file:///{}/{}'.format(cg_name, source.replace("\\", "/")))
	print('\t\t\t<Component Id="cmp{}" Directory="{}" Guid="{{{}}}">'.format(cmp_id, dir_id, guid))
	print('\t\t\t\t<File Id="fil{}" KeyPath="yes" Source="{}" />'.format(cmp_id, source))
	print('\t\t\t</Component>')
print('\t\t</ComponentGroup>')
print('\t</Fragment>')

#directories
for id, pid, name in dirlist.values():
	print('\t<Fragment>')
	print('\t\t<DirectoryRef Id="{}">'.format(pid))
	print('\t\t\t<Directory Id="{}" Name="{}" />'.format(id, name))
	print('\t\t</DirectoryRef>')
	print('\t</Fragment>')

#the footer
print('</Wix>')
