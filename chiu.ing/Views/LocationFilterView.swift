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
                VStack(alignment: .leading, spacing: Theme.Space.l) {
                    mapCard
                    currentLocationToggle
                    citySearch
                    radiusSlider
                    popularStrip
                    Spacer(minLength: Theme.Space.xxl)
                }
                .padding(.horizontal, Theme.Space.gutter)
            }
            applyBar
        }
        .background(Theme.Palette.surface.ignoresSafeArea())
        .onAppear {
            city = session.locationFilter.city
            radiusMiles = session.locationFilter.radiusMiles
            useCurrent = session.locationFilter.usingCurrentLocation
        }
    }

    private var handle: some View {
        Capsule()
            .fill(Theme.Palette.borderStrong)
            .frame(width: 36, height: 4)
            .padding(.vertical, Theme.Space.s)
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Location").eyebrowStyle()
                Text("Where to chiu")
                    .font(Theme.Typography.title)
                    .foregroundColor(Theme.Palette.ink)
            }
            Spacer()
            Button("Close") { dismiss() }
                .font(Theme.Typography.label)
                .foregroundColor(Theme.Palette.inkSecondary)
        }
        .padding(.horizontal, Theme.Space.gutter)
        .padding(.bottom, Theme.Space.m)
    }

    private var mapCard: some View {
        Map(position: $position)
            .frame(height: 200)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.medium, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.medium, style: .continuous)
                    .stroke(Theme.Palette.border, lineWidth: 1)
            )
            .overlay(
                Circle()
                    .strokeBorder(Theme.Palette.accent, lineWidth: 2)
                    .frame(
                        width: max(CGFloat(radiusMiles) * 14, 44),
                        height: max(CGFloat(radiusMiles) * 14, 44)
                    )
                    .allowsHitTesting(false)
            )
    }

    private var currentLocationToggle: some View {
        Toggle(isOn: $useCurrent) {
            HStack(spacing: Theme.Space.xs) {
                Image(systemName: "location")
                    .foregroundColor(Theme.Palette.ink)
                Text("Use current location")
                    .font(Theme.Typography.body)
                    .foregroundColor(Theme.Palette.ink)
            }
        }
        .tint(Theme.Palette.ink)
        .padding(Theme.Space.m)
        .chiuCard()
    }

    private var citySearch: some View {
        HStack(spacing: Theme.Space.s) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14))
                .foregroundColor(Theme.Palette.inkTertiary)
            TextField("Search city or area", text: $city)
                .font(Theme.Typography.body)
                .foregroundColor(Theme.Palette.ink)
        }
        .padding(.horizontal, Theme.Space.m)
        .padding(.vertical, 12)
        .background(Theme.Palette.surfaceElevated)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.medium, style: .continuous)
                .stroke(Theme.Palette.border, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.medium, style: .continuous))
    }

    private var radiusSlider: some View {
        VStack(alignment: .leading, spacing: Theme.Space.xs) {
            HStack {
                Text("Search radius").eyebrowStyle()
                Spacer()
                Text("\(Int(radiusMiles)) mi")
                    .font(Theme.Typography.label)
                    .foregroundColor(Theme.Palette.ink)
            }
            Slider(value: $radiusMiles, in: 1...50, step: 1)
                .tint(Theme.Palette.ink)
        }
        .padding(Theme.Space.m)
        .chiuCard()
    }

    private var popularStrip: some View {
        VStack(alignment: .leading, spacing: Theme.Space.s) {
            Text("Popular cities").eyebrowStyle()
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Theme.Space.xs) {
                    ForEach(popularCities, id: \.self) { c in
                        Button { city = c } label: {
                            Text(c)
                                .font(Theme.Typography.label)
                                .padding(.horizontal, Theme.Space.m)
                                .padding(.vertical, 8)
                                .foregroundColor(city == c ? .white : Theme.Palette.ink)
                                .background(city == c ? Theme.Palette.ink : Theme.Palette.surfaceElevated)
                                .overlay(
                                    Capsule().stroke(
                                        city == c ? Theme.Palette.ink : Theme.Palette.border,
                                        lineWidth: 1
                                    )
                                )
                                .clipShape(Capsule())
                        }
                    }
                }
            }
        }
    }

    private var applyBar: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(Theme.Palette.border)
                .frame(height: 1)
            Button {
                session.locationFilter = LocationFilter(
                    city: city.isEmpty ? session.locationFilter.city : city,
                    radiusMiles: radiusMiles,
                    usingCurrentLocation: useCurrent
                )
                dismiss()
            } label: {
                Text("Apply filter")
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding(.horizontal, Theme.Space.gutter)
            .padding(.vertical, Theme.Space.m)
        }
    }
}
