//
//  DetailVC.swift
//  WeatherGift
//
//  Created by Richard Jove on 10/9/19.
//  Copyright © 2019 Richard Jove. All rights reserved.
// Richard

import UIKit
import CoreLocation

private let dateFormatter: DateFormatter = {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "EEEE, MMM dd, y"
    return dateFormatter
}() //Need this extra syntax here

class DetailVC: UIViewController {

    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var temperatureLabel: UILabel!
    @IBOutlet weak var summaryLabel: UILabel!
    @IBOutlet weak var currentImage: UIImageView!
    @IBOutlet weak var tableView: UITableView!
    
    var currentPage = 0
    var locationsArray = [WeatherLocation]()
    var locationManager: CLLocationManager!
    var currentLocation: CLLocation!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self //TableView will be sending some messages back, calling some functions
        tableView.dataSource = self
        if currentPage != 0 {
            self.locationsArray[currentPage].getWeather {
                self.updateUserInterface()
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if currentPage == 0 {
            getLocation()
        }
    }
    
    func updateUserInterface() {
        let location = locationsArray[currentPage]
        locationLabel.text = location.name
        let dateString = location.currentTime.format(timeZone: location.timeZone, dateFormatter: dateFormatter)
        dateLabel.text = dateString
        temperatureLabel.text = location.currentTemp
        summaryLabel.text = location.currentSummary
        currentImage.image = UIImage(named: location.currentIcon)
        tableView.reloadData()
    }

}

extension DetailVC: CLLocationManagerDelegate {
    
    func getLocation() {
        locationManager = CLLocationManager()
        locationManager.delegate = self //Can't do this in viewDidLoad until create location manager
    }
    
    func handleLocationAuthorizationStatus(status: CLAuthorizationStatus) {
        switch status {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .authorizedAlways, .authorizedWhenInUse:
            locationManager.requestLocation()
        case .denied:
            print("Sorry, we cannot show the location because the user has not authorized it.")
        case .restricted:
            print("Access denied. Likely parental controls are restricting location services in this app.")
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        handleLocationAuthorizationStatus(status: status)
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let geoCoder = CLGeocoder() //Parentheses mean construct using this class an object of type geocoder
        var place = ""
        currentLocation = locations.last
        let currentLatitude = currentLocation.coordinate.latitude
        let currentLongitude = currentLocation.coordinate.longitude
        let currentCoordinates = "\(currentLatitude),\(currentLongitude)"
        geoCoder.reverseGeocodeLocation(currentLocation, completionHandler: {placemarks, error in
            if placemarks != nil {
                let placemark = placemarks?.last
                place = (placemark?.name)!
            } else {
                print("Error retrieving place. Error code: \(error!)")
                place = "Unknown Weather Location"
            }
            self.locationsArray[0].name = place //Need "self" because we are in a closure.
            self.locationsArray[0].coordinates = currentCoordinates
            self.locationsArray[0].getWeather {
                self.updateUserInterface()
            }
        })
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Failed to get user location.")
    }
}

extension DetailVC: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return locationsArray[currentPage].dailyForecastArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "DayWeatherCell", for: indexPath) as! DayWeatherCell
        let dailyForecast = locationsArray[currentPage].dailyForecastArray[indexPath.row]
        let timeZone = locationsArray[currentPage].timeZone
        cell.update(with: dailyForecast, timeZone: timeZone)
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
    
    
}
