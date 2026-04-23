//
//  SupabaseManager.swift
//  Layover
//
//  Created by Maxwell Hu on 4/17/26.
//

import Foundation
import Supabase

enum SupabaseManager {

    static let client: SupabaseClient = {
        guard let path = Bundle.main.path(forResource: "Secrets", ofType: "plist"),
              let dict = NSDictionary(contentsOfFile: path),
              let urlString = dict["SUPABASE_URL"] as? String,
              let anonKey = dict["SUPABASE_ANON_KEY"] as? String,
              let url = URL(string: urlString)
        else {
            fatalError("Missing SUPABASE_URL or SUPABASE_ANON_KEY in Secrets.plist")
        }

        return SupabaseClient(
            supabaseURL: url,
            supabaseKey: anonKey,
            options: .init(
                auth: .init(autoRefreshToken: true)
            )
        )
    }()
}
