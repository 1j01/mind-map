
# [MindMap][app]

Map your mind without ugly boxes.

*This is not a good mind mapping application (yet).*

### (Maybe "Minmap"?)

Minmap is a minimal mind mapping app.
Less distracting UI means a stronger focus on content.

### TODO

* Infinite scrolling
	* FIXME: Work around horrible glitchiness in chrome
	* FIXME: Clicking (creating a node) outside of #document-content scrolls
	* FIXME: Generally doesn't really work
* Structure
	* Traversing up/down, left/right
	* Collapsing/expanding
	* Adding/removing
* Formatting
	* Links (pasting plain, creating from existing text, editing existing links...)
	* Images (drag and drop to "upload" (or upload))
* Prevent XSS
* Use something better than `contenteditable`
	* Still needs to carry undos/redos between nodes
* Subtle blobby highlight around nodes
* Connections
	* Add text
	* Change color
* Firebase security rules
* Unobtrusive savedness notification
* User presence
	* Cursors and selections
	* Pointers to where someone is in the document
* GUI to create and manage documents
* Look for new images added, listen for onload and reposition immediately
* Store history and allow rolling back changes
* Chrome app
* Themes
* Mobile
* Better fonts and icons
* Optimize app load time

[app]: http://1j01.github.io/mind-map/?mind-map
