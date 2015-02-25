import QtQuick 2.0
import QtQuick.XmlListModel 2.0
import QtQuick.Controls 1.3 
import QtQuick.Controls.Styles 1.3
import QtQuick.Layouts 1.1

Rectangle {
  id: pictureWidget
  property variant pictures

  /* Raised each time a picture is re-ordered */
  signal pictureMoved(int indexFrom, int indexTo)
  /* Raised when a picture is deleted/discarded */
  signal pictureDiscarded(int index)

  width: 300
  /* First element is only a little picture viewer, as a box that contains an image  */
  Rectangle {
    id: viewerWrapper
    width: pictureWidget.width 
    height: width
    anchors.top: parent.top
    anchors.left: parent.left
    Image {
      id: viewer
      anchors.fill: parent
      anchors.centerIn: parent
      fillMode: Image.PreserveAspectCrop
      sourceSize.width: 2 * viewerWrapper.width
      clip: true
    }
  }

  /* Just a separator */
  Separator {
    id: separator1
    anchors.top: viewerWrapper.bottom
  }

  ComboBox {
    id: filters
    anchors.top: separator1.bottom
    anchors.right: parent.right
    width: pictureWidget.width / 3
    height: 25
    model: ListModel {
      id: filterModel
      ListElement { text: "All"; value: -1 }
      ListElement { text: "New"; value: 0 }
      ListElement { text: "Reconstruction"; value: 1 }
      ListElement { text: "Processed"; value: 3 }
      ListElement { text: "Discarded"; value: 2 }
    }
    /* Filter all pictures below */
    onCurrentIndexChanged: {
      /* Clear the model */
      listView.model.clear()

      /* Populate the model; This will repaint components according to the new filter */
      for(var i = 0; i < pictures.count; i++) {
        listView.model.append(pictures.get(i));
      }
    }  
  }

  /* Just a separator */
  Separator {
    id: separator2
    anchors.top: filters.bottom
  }

  /* Then is the complete list of pictures, only names are displayed */
  Item {
    anchors.top: separator2.bottom
    anchors.bottom: parent.bottom
    width: parent.width

    /* ScrollView will easily handle the data overflow */
    ScrollView {
      id: scrollView 

      anchors.fill: parent
      /* Little hack because it seems that  ****** people like putting default padding */
      Component.onCompleted: {
        __style.padding.top = 0
        __style.padding.bottom = 0
        __style.padding.left = 0
        __style.padding.right = 0
      }
      ListView {
        id: listView
        boundsBehavior: Flickable.StopAtBounds
        currentIndex: 0
        model: ListModel {}
        clip: true
        delegate: pictureDelegate
        focus: true
        highlight: highlightDelegate
        highlightMoveDuration: 0
      }
    }
  }
  /* Define delegate for the view */
  Component {
    id: pictureDelegate
    Item {
      id: pictureWrapper
        
      property int filter: filterModel.get(filters.currentIndex).value

      height: visible ? pictureName.height : 0
      width: pictureWidget.width
      visible: filter == status || filter == -1

      /* Initialize the viewer with the first loaded element of the model */
      Component.onCompleted: {
        if(index == listView.currentIndex) {
          viewer.source = image
        }
      }
      RowLayout {
        /* Icon that represent the image status */
        anchors.left: parent.left
        anchors.leftMargin: spacing
        spacing: 10
        
        Image {
          anchors.verticalCenter: parent.verticalCenter
          height: width
          source: icon
          sourceSize.height: width
          sourceSize.width: width
          width: pictureName.height * 0.75
        }
        Text {
          id: pictureName
          anchors.top: parent.top
          text: name
          color: "#000000"
        }
      }
      /* Handle mouseClick in order to update the pictureViewer. Also
       in charge of reordering element via drag'n'drop */
       MouseArea {
         id: dragArea

         /* Properties use to handle the drag and drop */
         property int positionStarted
         property int positionEnded
         property int indexMoved: Math.floor((positionEnded - positionStarted)/pictureWrapper.height)

         anchors.fill: parent
         drag.axis: Drag.YAxis
         drag.minimumY: 0
         drag.maximumY: listView.model.count * pictureWrapper.height

         onPressed: {
           positionStarted = pictureWrapper.y
           /* Sounds glitchy, but we also initialize the positionEnded to handle simpleClick for which,
            onPositionChanged never get called */
            positionEnded = positionStarted
            dragArea.drag.target = pictureWrapper
          }
          onPositionChanged: {
            pictureWrapper.opacity = 0.5
            positionEnded = pictureWrapper.y
          }
          /* On release, click or move element, depending of the executed action */
          onReleased: {
            pictureWrapper.opacity = 1
            dragArea.drag.target = null
            pictureWrapper.y = positionStarted
            /* indexMoved == 0 means that the item wasn't drag, so it's considered as a click */
            if (indexMoved != 0) {
              /* As some item are not visible, we have to find the good one */
              var newIndex = index;
              var moves = indexMoved; //In order to not unbind the property
              var incr = indexMoved < 0 ? -1 : 1; //We can drag up or down
              while(moves != 0) {
                newIndex += incr;
                var elem  = listView.model.get(newIndex)
                if(!elem || elem.status == filter || filter == -1){
                  moves -= incr;
                }
              }
              /* Ensure that the index isn't out of bounds */
              newIndex = Math.min(Math.max(0, newIndex), listView.model.count - 1);
              
              /* Send the corresponding signal */
              pictureMoved(index, newIndex)

              /* Now, newIndex holds the index new index of the moved item */
              listView.model.move(index, newIndex, 1)
              pictures.move(index, newIndex, 1)


            } else {
              /* Only a click, so select the element in the viewer */
              listView.currentIndex = index
              viewer.source = image
            }
          }
        }
      }
    }

    /* Define delegate for the highlightning */
    Component {
      id: highlightDelegate
      Rectangle {
        color: "#1db7ff"
        y: listView.currentItem.y
      }
    }
  }
