/**
 * The CLIK ScrollBar displays and controls the scroll position of another component. It adds interactivity to the ScrollIndicator with a draggable thumb button, as well as optional “up” and “down” arrow buttons, and a clickable track.

	<b>Inspectable Properties</b>
	The inspectable properties of the ScrollBar are similar to ScrollIndicator with one addition:<ul>
	<li><i>scrollTarget</i>: Set a TextArea or normal multiline textField as the scroll target to automatically respond to scroll events. Non-text field types have to manually update the ScrollIndicator properties.</li>
	<li><i>trackMode</i>: When the user clicks on the track with the cursor, the scrollPage setting will cause the thumb to continuously scroll by a page until the cursor is released. The scrollToCursor setting will cause the thumb to immediately jump to the cursor and will also transition the thumb into a dragging mode until the cursor is released.</li>
	<li><i>visible</i>: Hides the component if set to false.</li>
	<li><i>disabled</i>: Disables the component if set to true.</li>
	<li><i>offsetTop</i>: Thumb offset at the top. A positive value moves the thumb's top-most position higher.</li>
	<li><i>offsetBottom</i>: Thumb offset at the bottom. A positive value moves the thumb's bottom-most position lower.</li>
	<li><i>enableInitCallback</i>: If set to true, _global.CLIK_loadCallback() will be fired when a component is loaded and _global.CLIK_unloadCallback will be called when the component is unloaded. These methods receive the instance name, target path, and a reference the component as parameters.  _global.CLIK_loadCallback and _global.CLIK_unloadCallback should be overridden from the game engine using GFx FunctionObjects.</li>
	<li><i>soundMap</i>: Mapping between events and sound process. When an event is fired, the associated sound process will be fired via _global.gfxProcessSound, which should be overridden from the game engine using GFx FunctionObjects.</li></ul>

	<b>States</b>
	The ScrollBar, similar to the ScrollIndicator, does not have explicit states. It uses the states of its child elements, the thumb, up, down and track Button components.

	<b>Events</b>
	All event callbacks receive a single Object parameter that contains relevant information about the event. The following properties are common to all events. <ul>
	<li><i>type</i>: The event type.</li>
	<li><i>target</i>: The target that generated the event.</li></ul>

	The events generated by the ScrollBar component are listed below. The properties listed next to the event are provided in addition to the common properties.<ul>
	<li><i>show</i>: The component’s visible property has been set to true at runtime.</li>
	<li><i>hide</i>: The component’s visible property has been set to false at runtime.</li>
	<li><i>scroll</i>: The scroll position has changed.<ul>
		<li><i>position</i>: The new scroll position. Number type. Values minimum position to maximum position. </li></ul></li></ul>
*/


import gfx.controls.Button;
import gfx.controls.ScrollIndicator;
import gfx.utils.Constraints;


[InspectableList("disabled", "visible", "inspectableScrollTarget", "trackMode", "offsetTop", "offsetBottom", "enableInitCallback", "soundMap")]
class gfx.controls.ScrollBar extends ScrollIndicator
{
	/* PUBLIC VARIABLES */

	/** The number of positions to scroll when the track is clicked in scrollPage mode */
	public var trackScrollPageSize: Number = 1;


	/* PRIVATE VARIABLES */

	private var dragOffset: Object;
	private var constraints: Constraints;
	private var _trackMode: String = "scrollPage";
	private var trackScrollPosition: Number = -1;
	private var trackDragMouseIndex: Number;


	/* STAGE ELEMENTS */

	/** A reference to the up arrow symbol in the ScrollBar, used to decrement the scroll position. */
	public var upArrow: Button;
	/** A reference to the down arrow symbol in the ScrollBar, used to increment the scroll position. */
	public var downArrow: Button;
	/** A reference to the thumb symbol in the ScrollBar, used to display the scrollPosition, as well as change it by dragging. */
	public var thumb: Button;
	/** A reference to the track symbol in the ScrollBar, used to determine the thumb's range, as well as jump to a position when clicked. */
	public var track: Button;


	/* INITIALIZATION */

	/**
	 * The constructor is called when a ScrollBar or a sub-class of ScrollBar is instantiated on stage or by using {@code attachMovie()} in ActionScript. This component can <b>not</b> be instantiated using {@code new} syntax. When creating new components that extend ScrollBar, ensure that a {@code super()} call is made first in the constructor.
	 */
	public function ScrollBar()
	{
		super();
	}


	/* PUBLIC FUNCTIONS */

	/**
	 * Disable this component. Focus (along with keyboard events) and mouse events will be suppressed if disabled.
	 */
	[Inspectable(defaultValue="false")]
	public function get disabled(): Boolean
	{
		return _disabled;
	}


	public function set disabled(value: Boolean): Void
	{
		if (_disabled == value) {
			return;
		}

		super.disabled = value;
		gotoAndPlay(_disabled ? "disabled" : "default");
		if (initialized) {
			upArrow.disabled = _disabled;
			downArrow.disabled = _disabled;
			track.disabled = _disabled;
		}
	}


	/**
	 * Set the scroll position to a number between the minimum and maximum.
	 */
	public function get position(): Number
	{
		return super.position;
	}


	public function set position(value: Number): Void
	{
		value = Math.round(value); // The value is rounded so that the scrolling represents the position properly. Particularly for TextFields.
		if (value == position) {
			return;
		}

		super.position = value;
		updateScrollTarget();
	}


	/**
	 * Set the behavior when clicking on the track. The scrollPage value will move the grip by a page in the direction of the click. The scrollToCursor value will move the grip to the exact position that was clicked and become instantly draggable.
	 */
	[Inspectable(type="String",enumeration="scrollPage,scrollToCursor",defaultValue="scrollPage")]
	public function get trackMode(): String
	{
		return _trackMode;
	}


	public function set trackMode(value: String): Void
	{
		if (value == _trackMode) {
			return;
		}

		_trackMode = value;
		if (initialized) {
			track.autoRepeat = (trackMode == "scrollPage");
		}
	}


	/** @exclude */
	public function get availableHeight(): Number
	{
		return track.height - thumb.height + offsetBottom + offsetTop;
	}


	/** @exclude */
	public function toString(): String
	{
		return "[Scaleform ScrollBar " + _name + "]";
	}


	/* PRIVATE FUNCTIONS */

	private function configUI(): Void
	{
		super.configUI();
		delete onRelease; // ScrollIndicator adds this to stop interactions.

		if (upArrow) {
			upArrow.addEventListener("click", this, "scrollUp");
			upArrow.useHandCursor = !_disabled;
			upArrow.disabled = _disabled;
			upArrow.focusTarget = this;
			upArrow.autoRepeat = true;
		}

		if (downArrow) {
			downArrow.addEventListener("click", this, "scrollDown");
			downArrow.useHandCursor = !_disabled;
			downArrow.disabled = _disabled;
			downArrow.focusTarget = this;
			downArrow.autoRepeat = true;
		}

		thumb.addEventListener("press", this, "beginDrag");
		thumb.useHandCursor = !_disabled;
		thumb.lockDragStateChange = true;

		track.addEventListener("press", this, "beginTrackScroll");
		track.addEventListener("click", this, "trackScroll");
		track.disabled = _disabled;
		track.autoRepeat = (trackMode == "scrollPage");

		Mouse.addListener(this);

		var r: Number = _rotation;
		_rotation = 0;
		constraints = new Constraints(this);
		// The upArrow doesn't need a constraints, since it sticks to top left.
		if (downArrow) { constraints.addElement(downArrow, Constraints.BOTTOM); }
		constraints.addElement(track, Constraints.TOP | Constraints.BOTTOM);
		_rotation = r;
	}


	private function draw(): Void
	{
		if (direction == "horizontal") {
			constraints.update(__height, __width);
		} else {
			constraints.update(__width, __height);
		}

		// Special case for textFields. Explicitly change the scroll properties as it may have changed.
		if (_scrollTarget instanceof TextField) {
			setScrollProperties(_scrollTarget.bottomScroll - _scrollTarget.scroll, 1, _scrollTarget.maxscroll);
		} else {
			updateThumb();
		}
	}


	private function updateThumb():Void {
		if (!initialized) {	// This ensures we do not try and resize the thumb until it is ready.
			invalidate();
			return;
		}

		if (_disabled) {
			return;
		}

		var per: Number = Math.max(1, maxPosition - minPosition + pageSize);
		var trackHeight: Number = track.height + offsetTop + offsetBottom;
		var space: Number = trackHeight;
		thumb.height = Math.max(10, Math.min(trackHeight, (pageSize / per) * space));

		var percent: Number = (_position - minPosition) / (maxPosition - minPosition);
		var top: Number = track._y - offsetTop;
		var yPos: Number = (percent * availableHeight) + top;

		thumb._y = Math.max(top, Math.min(track._y + track.height - thumb.height + offsetBottom, yPos));
		thumb.visible = !(isNaN(percent) || maxPosition <= 0 || maxPosition == Infinity);

		// Set the up and down arrow states
		if (thumb.visible) {
			track.disabled = false;
			if (upArrow) {
				if (_position == minPosition) {
					upArrow.disabled = true;
				} else {
					upArrow.disabled = false;
				}
			}
			if (downArrow) {
				if (_position == maxPosition) {
					downArrow.disabled = true;
				} else {
					downArrow.disabled = false;
				}
			}
		}
		else {
			if (upArrow) {
				upArrow.disabled = true;
			}

			if (downArrow) {
				downArrow.disabled = true;
			}

			track.disabled = true;
		}
	}


	private function scrollUp(): Void
	{
		position -= pageScrollSize;
	}


	private function scrollDown(): Void
	{
		position += pageScrollSize;
	}


	private function beginDrag(): Void
	{
		if (isDragging == true) {
			return;
		}

		isDragging = true;
		onMouseMove = doDrag;
		onMouseUp = endDrag;
		dragOffset = {y:_ymouse - thumb._y};
	}


	private function doDrag(): Void
	{
		var percent: Number = (_ymouse - dragOffset.y - track._y) / availableHeight;
		position = minPosition + percent * (maxPosition - minPosition);
	}


	private function endDrag(): Void
	{
		delete onMouseUp;
		delete onMouseMove;
		isDragging = false;
		// If the thumb became draggable on a track press,
		// manually generate the thumb events.
		if (trackDragMouseIndex != undefined) {
			if (!thumb.hitTest(_root._xmouse, _root._ymouse)) {
				thumb.onReleaseOutside(trackDragMouseIndex);
			} else {
				thumb.onRelease(trackDragMouseIndex);
			}
		}
		delete trackDragMouseIndex;
	}


	private function beginTrackScroll(e: Object): Void
	{
		var percent: Number = (_ymouse - thumb.height/2 - track._y) / availableHeight;
		trackScrollPosition = Math.round(percent * (maxPosition - minPosition) + minPosition);
		// Special mode on SHIFT key that scrolls to cursor position and starts thumb drag
		// regardless of track mode
		if (Key.isDown(Key.SHIFT) || trackMode == "scrollToCursor") {
			position = trackScrollPosition;
			trackDragMouseIndex = e.controllerIdx;
			thumb.onPress(trackDragMouseIndex);
			dragOffset = {y:thumb.height/2};
		}
	}


	private function trackScroll(): Void
	{
		if (isDragging || position == trackScrollPosition) {
			return;
		}

		var dev: Number = ((position < trackScrollPosition) ? trackScrollPageSize : -trackScrollPageSize);
		var newPos: Number = position + dev;
		position = (dev < 0) ? Math.max(newPos, trackScrollPosition) : Math.min(newPos, trackScrollPosition);
	}


	private function updateScrollTarget(): Void
	{
		if (_scrollTarget == null) {
			return;
		}

		if (_scrollTarget && !_disabled) {
			_scrollTarget.scroll = _position;
		}
	}


	private function scrollWheel(delta: Number): Void
	{
		position -= (delta * pageScrollSize);
	}
}
