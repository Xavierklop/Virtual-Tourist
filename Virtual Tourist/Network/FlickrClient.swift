//
//  FlickrClient.swift
//  Virtual Tourist
//
//  Created by Hao Wu on 13.07.19.
//  Copyright © 2019 Hao Wu. All rights reserved.
//

import Foundation

class FlickrClient {
    private  static let photosPerPage = 21
    
    struct Auth {
        static let uniqueKey = "f896f37933075e5a079db20bb21899f8"
    }
    
    enum Endpoints {
        static let base = "https://www.flickr.com/services/rest"
        
    }

    class func searchPhotosByLocation(pin: Pin, completion: @escaping (FlickrResponse? , Error?) -> Void) {
        
        guard let url = buildSearchPhotosURL(lat: pin.latitude, long: pin.longitude, pinPages: Int(pin.pages)) else {
            print("Build url failed")
            return
        }
        
        taskForGETRequest(url: url, response: FlickrResponse.self) { (response, error) in
            if let response = response {
                completion(response, nil)
            } else {
                completion(nil, error)
            }
        }
    }
    
    class func downloadFlickrImage(photo: Photo, completion: @escaping (Data? , Error?) -> Void) {
        guard let urlString = photo.url, let url = URL(string: urlString) else {
            print("NO url for this photo")
            return
        }
        let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
            DispatchQueue.main.async {
                completion(data, error)
            }
        }
        task.resume()
    }
    
    class func taskForGETRequest<ResponseType: Decodable>(url: URL, response: ResponseType.Type, completion: @escaping (ResponseType?, Error?) -> Void) {

        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data else {
                DispatchQueue.main.async {
                    completion(nil, error)
                }
                return
            }
            
            let decoder = JSONDecoder()
            do {
                let responseObject = try decoder.decode(ResponseType.self, from: data)
                DispatchQueue.main.async {
                    completion(responseObject, nil)
                }
            } catch {
                DispatchQueue.main.async {
                    completion(nil, error)
                }
            }
        }
        task.resume()
    }
    
    class func buildSearchPhotosURL(lat: Double, long: Double, pinPages: Int) -> URL? {
        var page: Int {
            if pinPages > 0 {
                let page = min(pinPages, 4000 / photosPerPage)
                return Int(arc4random_uniform(UInt32(page)) + 1)
            }
            return 1
        }

        var urlComponent = URLComponents(string: Endpoints.base)!
        urlComponent.queryItems = [
            URLQueryItem(name: "method", value: "flickr.photos.search"),
            URLQueryItem(name: "api_key", value: Auth.uniqueKey),
            URLQueryItem(name: "lat", value: "\(lat)"),
            URLQueryItem(name: "lon", value: "\(long)"),
            URLQueryItem(name: "per_page", value: "\(photosPerPage)"),
            URLQueryItem(name: "format", value: "json"),
            URLQueryItem(name: "page", value: "\(page)"),
            URLQueryItem(name: "nojsoncallback", value: "1"),
            URLQueryItem(name: "extras", value: "url_n")
            ] as [URLQueryItem]

        return  urlComponent.url

    }
    
}
