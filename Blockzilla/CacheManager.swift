/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

class URLCacheManeger {
    /**
     Sets the URLCache capacity
     - parameters:
        - memoryCapacity: The updated memory capacity in MB
        - diskCapacity: The updated disk capacity in MB
    */
    func setCacheCapacity(memoryCapacity: Int, diskCapacity: Int) {
        URLCache.shared.memoryCapacity = memoryCapacity * 1024 * 1024
        URLCache.shared.diskCapacity = diskCapacity * 1024 * 1024
    }

    /**
     Fetch an image from the URLCache
     
     - parameters:
        - path: The path of the image you want to lookup
    */
    func fetchImageFromCache(path: String) -> UIImage? {
        guard let url = URL(string: path) else { return nil }
        let request = URLRequest(url: url)
        let response = URLCache.shared.cachedResponse(for: request)
        guard let data = response?.data, let image = UIImage(data: data) else { return nil }

        return image
    }
}
