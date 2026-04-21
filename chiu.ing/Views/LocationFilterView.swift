import SwiftUI
import MapKit

struct LocationFilterView: View {
    @EnvironmentObject var session: SessionStore
    @Environment(\.dismiss) private var dismiss

    @State private var city: String = ""
    @State private var radiusMiles: Double = 5
    @State private var useCurrent: Bool = false
    @State private var position: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 33.7490, longitude: -84.3880),
            span: MKCoordinateSpan(latitudeDelta: 0.2, longitudeDelta: 0.2)
        )
    )

    private let popularCities = ["Atlanta", "New York", "Los Angeles", "Chicago", "Austin", "Seattle"]

    var body: some View {
        VStack(spacing: 0) {
            handle
            header
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    mapCard
                    currentLocationToggle
                    citySearch
                    radiusSlider
                    popularStrip
                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 16)
            }
            applyBar
        }
        .background(Theme.Palette.cream.ignoresSafeArea())
        .onAppear {
            city = session.locationFilter.city
            radiusMiles = session.locationFilter.radiusMiles
            useCurrent = session.locationFilter.usingCurrentLocation
        }
    }

    private var handle: some View {
        Capsule()
            .fill(Theme.Palette.charcoal.opacity(0.2))
            .frame(width: 42, height: 5)
            .padding(.vertical, 10)
    }

    private var header: some View {
        HStack {
            Text("Where to chiu")
                .font(Theme.Typography.title)
            Spacer()
            Button("Close") { dismiss() }
                .font(Theme.Typography.caption)
                .foregroundColor(Theme.Palette.charcoal.opacity(0.6))
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }

    private var mapCard: some View {
        Map(position: $position)
            .frame(height: 180)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                Circle()
                    .strokeBorder(Theme.Palette.sunsetOrange, lineWidth: 2)
                    .frame(width: max(CGFloat(radiusMiles) * 14, 40),
                           height: max(CGFloat(radiusMiles) * 14, 40))
                    .allowsHitTesting(false)
            )
    }

    private var currentLocationToggle: some View {
        Toggle(isOn: $useCurrent) {
            HStack(spacing: 8) {
                Image(systemName: "location.circle.fill")
                    .foregroundColor(Theme.Palette.skyBlue)
                Text("Use current location")
            }
            .font(Theme.Typography.body)
        }
        .tint(Theme.Palette.sunsetOrange)
        .padding(14)
        .chiuCard()
    }

    private var citySearch: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(Theme.Palette.charcoal.opacity(0.5))
            TextField("Search city or area", text: $city)
                .font(Theme.Typography.body)
        }
        .padding(14)
        .chiuCard()
    }

    private var radiusSlider: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Radius")
                    .font(Theme.Typography.headline)
                Spacer()
                Text("\(Int(radiusMiles)) mi")
                    .font(Theme.Typography.caption)
                    .foregroundColor(Theme.Palette.sunsetOrange)
                    .fontWeight(.bold)
            }
            Slider(value: $radiusMiles, in: 1...50, step: 1)
                .tint(Theme.Palette.sunsetOrange)
        }
        .padding(14)
        .chiuCard()
    }

    private var popularStrip: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Popular cities")
                .font(Theme.Typography.headline)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(popularCities, id: \.self) { c in
                        Button {
                            city = c
                        } label: {
                            Text(c)
                                .font(Theme.Typography.caption)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(city == c
                                            ? AnyView(Theme.Palette.gradientWarm)
                                            : AnyView(Color.white))
                                .foregroundColor(city == c ? .white : Theme.Palette.charcoal)
                                .clipShape(Capsule())
                        }
                    }
                }
            }
        }
    }

    private var applyBar: some View {
        Button {
            session.locationFilter = LocationFilter(
                city: city.isEmpty ? session.locationFilter.city : city,
                radiusMiles: radiusMiles,
                usingCurrentLocation: useCurrent
            )
            dismiss()
        } label: {
            Text("Apply filter")
                .font(Theme.Typography.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Theme.Palette.gradientWarm)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .padding(16)
        }
    }
}
