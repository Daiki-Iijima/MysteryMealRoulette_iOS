//
//  ViewController.swift
//  MysteryMealRoulette
//
//  Created by 飯島大樹 on 2023/09/28.
//

import UIKit
import GoogleMaps
import GooglePlaces
import CoreLocation

class ViewController: UIViewController, CLLocationManagerDelegate {
    
    @IBOutlet weak var mapDrawView: UIView!
    let locationManager = CLLocationManager()  // 位置情報マネージャーを作成
    var mapView: GMSMapView?  // Google マップビューを保持する変数
    
    var places = [GMSPlace]()  // 取得した情報
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 位置情報の権限を要求
        locationManager.delegate = self  // 位置情報マネージャーのデリゲートを設定
        locationManager.requestWhenInUseAuthorization()  // 位置情報利用の権限を要求
    }
    
    // 位置情報の権限が変更された時に呼ばれるメソッド
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedWhenInUse {
            // 位置情報の権限が与えられたので、位置情報の更新を開始
            locationManager.startUpdatingLocation()
        }
    }
    
    // 位置情報が更新された時に呼ばれるメソッド
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        // 最新の位置情報を取得
        if let location = locations.last {
            // 位置情報の更新を停止してバッテリーを節約
            locationManager.stopUpdatingLocation()
            
            // 地図を更新
            let camera = GMSCameraPosition.camera(withLatitude: location.coordinate.latitude, longitude: location.coordinate.longitude, zoom: 16.0)
            mapView = GMSMapView.map(withFrame: self.view.frame, camera: camera)
            mapView?.settings.myLocationButton = true  // 現在位置ボタンを表示
            mapView?.isMyLocationEnabled = true  // 現在位置を有効にする
            mapDrawView.addSubview(mapView!)  // マップビューを画面に追加
        }
    }
    @IBAction func clickFindRestaurants(_ sender: Any) {
        guard let currentLocation = mapView?.myLocation?.coordinate else {
            print("Current location is not available.")
            return
        }
        
        // Places APIのクエリを構築
        let placeService = PlacesService(apiKey: API_KEY)
        placeService.lookForPlaces(near: currentLocation, radius: 1000, type: "restaurant") { (results, error) in
            guard error == nil else {
                print("Error: \(error!.localizedDescription)")
                return
            }
            
            if let results = results {
                //  取得した情報を保存
                self.places = results
                for place in results {
                    // 各レストランにピンを刺す
                    let marker = GMSMarker()
                    marker.position = place.coordinate
                    marker.title = place.name
                    marker.map = self.mapView
                }
            }
        }
        showRandomRestaurantDetail()
    }
    
    func showRandomRestaurantDetail() {
        guard !places.isEmpty else {
            print("No restaurants found.")
            return
        }
        
        let randomIndex = Int(arc4random_uniform(UInt32(places.count)))
        let randomPlace = places[randomIndex]
        
        let alertController = UIAlertController(title: randomPlace.name, message: "Location: \(randomPlace.coordinate.latitude), \(randomPlace.coordinate.longitude)", preferredStyle: .alert)
        
        // 「ここに行く」ボタンのアクション
        let goAction = UIAlertAction(title: "ここに行く", style: .default) { (action) in
            // Google Mapsアプリを開いてルートを案内する
            let googleMapsURLString = "comgooglemaps://?saddr=&daddr=\(randomPlace.coordinate.latitude),\(randomPlace.coordinate.longitude)&directionsmode=driving"
            if let googleMapsURL = URL(string: googleMapsURLString), UIApplication.shared.canOpenURL(googleMapsURL) {
                UIApplication.shared.open(googleMapsURL, options: [:], completionHandler: nil)
            } else {
                print("Google Maps app is not installed.")
            }
        }
        
        // 「もう一度」ボタンのアクション
        let retryAction = UIAlertAction(title: "もう一度", style: .default) { (action) in
            // 再度ランダムに食べ物やさんを選び、詳細を表示する
            self.showRandomRestaurantDetail()
        }
        
        alertController.addAction(goAction)
        alertController.addAction(retryAction)
        present(alertController, animated: true, completion: nil)
    }
}
