//
//  EKMapsView.swift
//  UICompanent
//
//  Created by Order Tiger on 9/6/21.
//  Copyright © All rights reserved.
//
#if canImport(SwiftUI) && os(iOS)
import SwiftUI
import GoogleMaps
import GooglePlaces
import CoreLocation

public typealias MapCompletion = ([String: String?]) -> Void

public func registerMapsKey(key: String) {
    GMSServices.provideAPIKey(key)
}

public func registerPlacesKey(key: String) {
    GMSPlacesClient.provideAPIKey(key)
}

public struct EKMarker {
    let name: String
    let icon: String
    let coordinate: CLLocationCoordinate2D
    
    public init(name: String, _ icon: String, _ coordinate: CLLocationCoordinate2D) {
        self.name = name
        self.icon = icon
        self.coordinate = coordinate
    }
    
    var gmsMarker: GMSMarker {
        let marker = GMSMarker(position: coordinate)
        marker.title = name
        marker.icon = UIImage(named: icon)
        marker.groundAnchor = .init(x: 0.5, y: 0.5)
        return marker
    }
}

public class EKMapsDataSource: ObservableObject {
    @Published public var coordinate: CLLocationCoordinate2D
    @Published public var zoom: Float
    @Published public var allowGesture: Bool
    public var insets: UIEdgeInsets
    public private(set) var markers: [EKMarker]
    public var isPolyline: GMSCoordinateBounds?
    public var completion: MapCompletion?
    
    public init(default coordinate: CLLocationCoordinate2D,
                zoom: Float = 18,
                markers: [EKMarker] = [],
                allowGesture: Bool = true,
                insets: UIEdgeInsets = .zero,
                completion: MapCompletion? = nil) {
        self.coordinate = coordinate
        self.zoom = zoom
        self.markers = markers
        self.allowGesture = allowGesture
        self.insets = insets
        self.completion = completion
    }
    
    public func addMarker(marker: EKMarker) {
        self.markers.removeAll()
        self.markers.append(marker)
        self.coordinate = marker.coordinate
    }
    
    public func drawPolyline(source: EKMarker, destination: EKMarker) {
        self.markers.removeAll()
        self.markers.append(contentsOf: [source, destination])
        self.isPolyline = .init(coordinate: source.coordinate, coordinate: destination.coordinate)
        objectWillChange.send()
    }
}

public struct EKMapsView: UIViewRepresentable {
    @ObservedObject private var datasource: EKMapsDataSource
    
    public init(datasource: EKMapsDataSource) {
        self.datasource = datasource
    }
    
    public func makeUIView(context: Self.Context) -> GMSMapView {
        let camera = GMSCameraPosition.camera(withLatitude: datasource.coordinate.latitude,
                                              longitude: datasource.coordinate.longitude, zoom: datasource.zoom)
        let mapView = GMSMapView.map(withFrame: CGRect.zero, camera: camera)
        mapView.delegate = context.coordinator
        return mapView
    }
    
    public func updateUIView(_ mapView: GMSMapView, context: Context) {
        DispatchQueue.main.async {
            mapView.clear()
            mapView.settings.scrollGestures = datasource.allowGesture
            mapView.padding = datasource.insets
            
            datasource.markers.map { $0.gmsMarker }.forEach { $0.map = mapView }
            updateCamara(mapView)
        }
    }
    
    private func updateCamara(_ mapView: GMSMapView) {
        if let bounds = datasource.isPolyline {
            let path = datasource.markers.reduce(into: GMSMutablePath()) { $0.add($1.coordinate) }
            let polyline = GMSPolyline(path: path)
            polyline.strokeWidth = 5.0
            polyline.strokeColor = .black
            polyline.map = mapView
            
            let update = GMSCameraUpdate.fit(bounds, with: datasource.insets)
            mapView.animate(with: update)
        } else {
            let position = GMSCameraPosition.camera(withLatitude: datasource.coordinate.latitude,
                                                    longitude: datasource.coordinate.longitude,
                                                    zoom: datasource.zoom)
            mapView.animate(to: position)
        }
    }
    
    public func makeCoordinator() -> Coordinator {
        Coordinator(datasource: datasource)
    }
}

extension EKMapsView {
    public class Coordinator: NSObject, GMSMapViewDelegate, ObservableObject {
        let datasource: EKMapsDataSource
        
        init(datasource: EKMapsDataSource) {
            self.datasource = datasource
        }
        
        public func mapView(_ mapView: GMSMapView, idleAt position: GMSCameraPosition) {
            guard let completion = self.datasource.completion else { return }
            Self.getMetaData(by: position.target, completion: completion)
        }
        
        public static func getMetaData(by coordinate: CLLocationCoordinate2D, completion: @escaping MapCompletion) {
            GMSGeocoder().reverseGeocodeCoordinate(coordinate) { placemark, error in
                guard error == nil else { return completion([:]) }
                guard let items = placemark?.firstResult()?.toDictionary else { return completion([:]) }
                completion(items)
            }
        }
    }
}

public extension GMSAddress {
    var toDictionary: [String: String?] {
        var items: [String: String?] = [:]
        items["addressline1"] = lines?.joined()
        items["addressline2"] = lines?.joined() 
        items["zipcode"] = postalCode
        items["postcode"] = postalCode
        items["coordinates"] = "\(coordinate.latitude),\(coordinate.longitude)"
        return items
    }
}

#if DEBUG
struct EKGoogleMapsView_Previews: PreviewProvider {
    static let datasource = EKMapsDataSource(default: .init(latitude: 42.857289, longitude: 74.601436))
    static var previews: some View {
        EKMapsView(datasource: datasource)
    }
}
#endif
#endif
