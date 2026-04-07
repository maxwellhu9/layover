//
//  ContentView.swift
//  Layover
//
//  Created by Maxwell Hu on 4/4/26.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var vm = LayoverViewModel()

    var body: some View {
        NavigationStack {
            Group {
                if vm.isLoading {
                    ProgressView("Finding places…")
                } else if vm.rows.isEmpty {
                    Text("No places found")
                } else {
                    List(vm.rows) { row in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(row.name).font(.headline)
                                Text(row.durationText)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: row.fits ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundStyle(row.fits ? .green : .red)
                                .font(.title2)
                        }
                    }
                }
            }
            .navigationTitle("Layover")
        }
        .onAppear { vm.loadPlaces() }
    }
}

#Preview {
    ContentView()
}
