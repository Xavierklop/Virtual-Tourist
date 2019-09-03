# Virtual-Tourist
An app using Flickr API create virtual photo albums for specifying travel locations around the world. This app allows users specify travel locations around the world, and create virtual photo albums for each location. The locations and photo albums will be stored in Core Data.
## Prerequisites
Xcode 10.1

Swift 4.2.1+

iOS 11.0+
## Installing
`git clone https://github.com/Xavierklop/Virtual-Tourist.git`
## Overview
The following features are provided by this app:

 1. Users can use standard pinch and drag gestures to zoom and scroll around the map.
 2. The center of the map and the zoom level can be persistent.
 3. Users can drop any number of pins on the map.
 4. Download the image of the corresponding position according to the longitude and latitude of each pin.
### Main View controllers
#### PhotoAlbumViewController
When the app first starts it will open to the map view. Users will be able to zoom and scroll around the map using standard pinch and drag gestures. The center of the map and the zoom level can be persistent. If the app is turned off, the map conld return to the same state when it is turned on again.

Tapping and holding the map drops a new pin. Users can place any number of pins on the map. When a pin is tapped, the app will navigate to the Photo Album view associated with the pin.
### TravelLocationViewController
If the user taps a pin that does not yet have a photo album, the app will download Flickr images associated with the latitude and longitude of the pin. If no images are found a “No Images” label will be displayed. If there are images, then they will be displayed in a collection view.

While the images are downloading, the photo album is in a temporary “downloading” state in which the New Collection button is disabled. The app should determine how many images are available for the pin location, and display a placeholder image for each.

Once the images have all been downloaded, the app could enable the New Collection button at the bottom of the page. Tapping this button can empty the photo album and fetch a new set of images. Note that in locations that have a fairly static set of Flickr images, “new” images might overlap with previous collections of images.


Users can be able to remove photos from an album by tapping them. Pictures will flow up to fill the space vacated by the removed photo. All changes to the photo album can be automatically made persistent.

If the user selects a pin that already has a photo album then the Photo Album view should display the album and the New Collection button can be enabled.
## Technical features
- Use Flickr API to search image.
- Use URLSession to manager all API request and download image.
- Use Decodable to parse JSON.
- Use Core Data to persistent Pin location and image. 
- All changes to the photo album can be automatically made persistent.
## License
This code may be used free of cost for a non-commercial purpose, provided the intended usage is notified to the owner via the below email address.
Any questions, please email wuhaocll@gmail.com
