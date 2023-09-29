//
//  PlacesService.swift
//  MysteryMealRoulette
//
//  Created by 飯島大樹 on 2023/09/30.
//

import Foundation
import CoreLocation
import GoogleMaps

class PlacesService {
    
    let apiKey: String
    
    init(apiKey: String) {
        self.apiKey = apiKey
    }
    
    func lookForPlaces(near location: CLLocationCoordinate2D, radius: Double, type: String, completion: @escaping ([GMSPlace]?, Error?) -> Void) {
        
        let urlString = "https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=\(location.latitude),\(location.longitude)&radius=\(radius)&type=\(type)&key=\(apiKey)"
        
        guard let url = URL(string: urlString) else {
            completion(nil, NSError(domain: "", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"]))
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
            guard error == nil else {
                completion(nil, error)
                return
            }
            
            guard let data = data else {
                completion(nil, NSError(domain: "", code: 500, userInfo: [NSLocalizedDescriptionKey: "No data received"]))
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let results = json["results"] as? [[String: Any]] {
                    var places = [GMSPlace]()
                    for result in results {
                        if let name = result["name"] as? String,
                           let geometry = result["geometry"] as? [String: Any],
                           let locationDict = geometry["location"] as? [String: Double],
                           let lat = locationDict["lat"],
                           let lng = locationDict["lng"] {
                            let place = GMSPlace(name: name, coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lng))
                            places.append(place)
                        }
                    }
                    completion(places, nil)
                } else {
                    completion(nil, NSError(domain: "", code: 500, userInfo: [NSLocalizedDescriptionKey: "Failed to parse JSON"]))
                }
            } catch {
                completion(nil, error)
            }
        }
        
        task.resume()
    }
}

// GMSPlaceは独自のモデルクラスであり、Google Maps SDKに含まれていないため、ここで定義する必要があります。
struct GMSPlace {
    let name: String
    let coordinate: CLLocationCoordinate2D
}
