"
I am a Spec drop list morph whose popup list is as wide as its widest item instead of as wide as the button.

Responsibility:
- I widen the popup list after the standard positioning, keeping it inside the World.

Collaborators:
- AbMorphicWidePopupDropListAdapter: builds me.

Constraint:
- I must not declare instance variables. AbMorphicWidePopupDropListAdapter changes the standard SpDropListMorph into me with #adoptInstance:, which fails when the object shape differs.
"
Class {
	#name : 'AbWidePopupDropListMorph',
	#superclass : 'SpDropListMorph',
	#category : 'AgenticBrowser-UI',
	#package : 'AgenticBrowser-UI'
}

{ #category : 'private' }
AbWidePopupDropListMorph >> positionList [

	super positionList.
	self listMorph width: self popupListWidth
]

{ #category : 'private' }
AbWidePopupDropListMorph >> popupListWidth [
	"Never narrower than the button, and never past the right edge of the World."

	^ (self width max: self widestItemWidth + self popupListPadding)
		  min: self world right - self boundsInWorld left
]

{ #category : 'private' }
AbWidePopupDropListMorph >> popupListPadding [
	"Room for the vertical scrollbar and the list insets, tuned by eye so no horizontal scrollbar appears."

	^ 30
]

{ #category : 'private' }
AbWidePopupDropListMorph >> widestItemWidth [

	| font |
	font := self listMorph font.
	^ (self list withIndexCollect: [ :item :index |
		   font widthOfString: (self wrapItem: item index: index) ])
		  inject: 0
		  into: [ :widest :itemWidth | widest max: itemWidth ]
]
