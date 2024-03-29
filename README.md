
# [Minmap][app]

Map your mind without ugly boxes.

*This is that good of a mind mapping application (yet).*

Minmap is a magical multiplayer minimal mind mapping app.
Less distracting UI means a stronger focus on content.

### TODO

* FIXME: tabbing to a node or typing or creating a node at the edge of the screen scrolls in the default broken way
* FIXME: flinging the view and then starting a drag, waiting for the view to move, and then dragging resets the view and looks bad; maybe velocity should be canceled when starting a drag
* FIXME: In MS IE and MS Edge the cursor gets left behind when dragging
* Structure
	* Traversing up/down, left/right
	* Collapsing/expanding
	* Adding/removing
* Formatting
	* Links (pasting plain, creating from existing text, editing existing links...)
	* Maybe *not* underline: underline is for links
	* Images (drag and drop to either "upload" or upload)
* Use something better than `contenteditable`
	* [Why ContentEditable is Terrible][]
	* Still needs to carry undos/redos between nodes
* Undo/redo buttons?
* Subtle blobby highlight around nodes
* Connections
	* Add text
	* Change color
* Handle being logged out or being on a document without an `owner_uid`
* Unobtrusive savedness notification
* User presence
	* Cursors and selections
	* Pointers to where someone is in the document
* UI to manage documents, like a popup menu with a list of documents (maybe including the new document button)
* Look for new images added, listen for onload and reposition immediately
* Store history and allow rolling back changes
* Themes
* Better font(s)?
* Mobile support
* Optimize app load time
* Rename repo
* Maybe add a mind map minimap to the Minmap mind mapping app

[app]: https://mind-map.web.app/
[Why ContentEditable is Terrible]: https://medium.com/medium-eng/why-contenteditable-is-terrible-122d8a40e480
