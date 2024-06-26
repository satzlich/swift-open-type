import CoreFoundation

class DeviceTable {
    let base: UnsafePointer<UInt8>

    init(base: UnsafePointer<UInt8>) {
        self.base = base
    }

    /// Smallest size to correct, in ppem
    func startSize() -> UInt16 {
        readUInt16(base + 0)
    }

    /// Largest size to correct, in ppem
    func endSize() -> UInt16 {
        readUInt16(base + 2)
    }

    /// Format of deltaValue array data: 0x0001, 0x0002, or 0x0003
    func deltaFormat() -> DeltaFormat {
        let deltaFormat = readUInt16(base + 4)
        assert(deltaFormat >= 0x0001 && deltaFormat <= 0x0003)
        return DeltaFormat(rawValue: deltaFormat)!
    }

    /// Array of compressed data
    func deltaValue(_ index: Int) -> UInt16 {
        readUInt16(base + 6 + index * 2)
    }

    // MARK: - query

    /// Returns delta value for given ppem.
    /// Returns 0 if not available.
    func getDeltaValue(ppem: UInt32, unitsPerEm: UInt32) -> Int32 {
        if ppem == 0 {
            return 0
        }

        let pixels = getDeltaPixels(ppem)

        if pixels == 0 {
            return 0
        }

        return Int32(Int64(pixels) * Int64(unitsPerEm) / Int64(ppem))
    }

    private func getDeltaPixels(_ ppem: UInt32) -> Int32 {
        let startSize = UInt32(self.startSize())
        let endSize = UInt32(self.endSize())

        if ppem < startSize || ppem > endSize {
            return 0
        }

        let f = deltaFormat().rawValue
        let s = Int(ppem - startSize)

        // Implementation note:
        //  For the sake of performance, we avoid multiplications and
        //  divisions, and use bit manipulations instead.

        let bitsPerItem = 1 << f
        // itemsPerWord = 16 / bitsPerItem
        let itemsPerWord = 1 << (4 - f)
        // wordIndex = s / itemsPerWord
        let wordIndex = s >> (4 - f)
        let word = deltaValue(wordIndex)

        // itemIndex = s % itemsPerWord
        let itemIndex = s & (itemsPerWord - 1)
        // x = word >> (16 - bitsPerItem - itemIndex * bitsPerItem)
        var x = Int(word >> (16 - ((itemIndex + 1) << f)))
        // E.g. for f = 2,
        //  mask = 0b1000
        //  ((1 << bitsPerItem) - 1) = 0b1111
        let mask = 1 << (bitsPerItem - 1)
        x = x & ((1 << bitsPerItem) - 1)
        return Int32((x ^ mask) - mask)
    }
}
