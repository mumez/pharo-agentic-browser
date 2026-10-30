"
I am a drop list whose popup list widens to fit its widest item, while the drop list button keeps the width given by its layout.

Responsibility:
- I let a narrow drop list (e.g. a status bar skill or model selector) show long item names in full when opened.

Collaborators:
- AbMorphicWidePopupDropListAdapter: the Morphic adapter I am rendered with.
"
Class {
	#name : 'AbWidePopupDropListPresenter',
	#superclass : 'SpDropListPresenter',
	#category : 'AgenticBrowser-UI',
	#package : 'AgenticBrowser-UI'
}

{ #category : 'specs' }
AbWidePopupDropListPresenter class >> adapterName [

	^ #AbMorphicWidePopupDropListAdapter
]
