"
I am the Morphic adapter for AbWidePopupDropListPresenter.

Responsibility:
- I build the standard Spec drop list morph and turn it into an AbWidePopupDropListMorph.

Collaborators:
- AbWidePopupDropListPresenter: the presenter I adapt.
- AbWidePopupDropListMorph: the morph class I build.
"
Class {
	#name : 'AbMorphicWidePopupDropListAdapter',
	#superclass : 'SpMorphicDropListAdapter',
	#category : 'AgenticBrowser-UI',
	#package : 'AgenticBrowser-UI'
}

{ #category : 'factory' }
AbMorphicWidePopupDropListAdapter >> buildWidget [
	"Change the class of the standard widget instead of copying SpMorphicDropListAdapter>>buildWidget, so future Spec changes to it are still picked up. AbWidePopupDropListMorph adds no instance variables, so the change keeps the object shape."

	| widget |
	widget := super buildWidget.
	AbWidePopupDropListMorph adoptInstance: widget.
	^ widget
]
