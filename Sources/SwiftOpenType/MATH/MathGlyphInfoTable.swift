import CoreText

public class MathGlyphInfoTable {
    let data: CFData
    let tableOffset: Offset16 /// offset from beginning of data

    init(data: CFData, tableOffset: Offset16) {
        self.data = data
        self.tableOffset = tableOffset
    }

    // MARK: - Header fields

    /// Offset to MathItalicsCorrectionInfo table, from the beginning of the MathGlyphInfo table.
    public func mathItalicsCorrectionInfoOffset() -> Offset16 {
        data.readOffset16(parentOffset: tableOffset, offset: 0)
    }

    /// Offset to MathTopAccentAttachment table, from the beginning of the MathGlyphInfo table.
    public func mathTopAccentAttachmentOffset() -> Offset16 {
        data.readOffset16(parentOffset: tableOffset, offset: 2)
    }

    /// Offset to ExtendedShapes coverage table, from the beginning of the MathGlyphInfo table.
    /// When the glyph to the left or right of a box is an extended shape variant, the (ink) box
    /// should be used for vertical positioning purposes, not the default position defined by
    /// values in MathConstants table. May be NULL.
    public func extendedShapeCoverageOffset() -> Offset16 {
        data.readOffset16(parentOffset: tableOffset, offset: 4)
    }

    /// Offset to MathKernInfo table, from the beginning of the MathGlyphInfo table.
    public func mathKernInfoOffset() -> Offset16 {
        data.readOffset16(parentOffset: tableOffset, offset: 6)
    }

    // MARK: - Sub-tables

    public var mathItalicsCorrectionInfoTable: MathItalicsCorrectionInfoTable? {
        let subtableOffset = mathItalicsCorrectionInfoOffset()
        
        if subtableOffset != 0 {
            return MathItalicsCorrectionInfoTable(data: data, tableOffset: self.tableOffset + subtableOffset)
        }
        return nil
    }
    
    /// The MathTopAccentAttachment table contains information on horizontal positioning of top math accents.
    public var mathTopAccentAttachmentTable: MathTopAccentAttachmentTable? {
        let subtableOffset = mathTopAccentAttachmentOffset()
        
        if subtableOffset != 0 {
            return MathTopAccentAttachmentTable(data: data, tableOffset: self.tableOffset + subtableOffset)
        }
        return nil
    }
    
    /// The glyphs covered by this table are to be considered extended shapes.
    public var extendedShapeCoverageTable: CoverageTable? {
        let subtableOffset = extendedShapeCoverageOffset()
        
        if subtableOffset != 0 {
            return CoverageTable(data: data, tableOffset: self.tableOffset + subtableOffset)
        }
        return nil
    }
    
    /// The MathKernInfo table provides mathematical kerning values used for kerning
    /// of subscript and superscript glyphs relative to a base glyph.
    public var mathKernInfoTable: MathKernInfoTable? {
        let subtableOffset = mathKernInfoOffset()
        
        if subtableOffset != 0 {
            return MathKernInfoTable(data: data, tableOffset: self.tableOffset + subtableOffset)
        }
        return nil
    }
}

public class MathItalicsCorrectionInfoTable {
    let data: CFData
    let tableOffset: Offset16 /// offset from the beginning of MATH table
    
    init(data: CFData, tableOffset: Offset16) {
        self.data = data
        self.tableOffset = tableOffset
    }

    /// Offset to Coverage table - from the beginning of MathItalicsCorrectionInfo table.
    public func italicsCorrectionCoverageOffset() -> Offset16 {
        data.readOffset16(parentOffset: tableOffset, offset: 0)
    }

    /// Number of italics correction values. Should coincide with the number of covered glyphs.
    public func italicsCorrectionCount() -> UInt16 {
        data.readUInt16(parentOffset: tableOffset, offset: 2)
    }

    /// Array of MathValueRecords defining italics correction values for each covered glyph.
    public func italicsCorrection(_ index: Int) -> MathValueRecord {
        data.readMathValueRecord(parentOffset: tableOffset, offset: 4 + index * MathValueRecord.byteSize)
    }

    public func coverageTable() -> CoverageTable {
        CoverageTable(data: data, tableOffset: tableOffset + italicsCorrectionCoverageOffset())
    }

    /// Return italics correction for glyphID in design units
    public func getItalicsCorrection(_ glyphID: UInt16) -> Int32? {
        let coverageTable = self.coverageTable()
        if let coverageIndex = coverageTable.getCoverageIndex(glyphID) {
            let mathValueRecord = italicsCorrection(coverageIndex)
            let value = data.evalMathValueRecord(parentOffset: tableOffset,
                                                 mathValueRecord: mathValueRecord)
            return value
        }
        return nil
    }
}

public class MathTopAccentAttachmentTable {
    let data: CFData
    let tableOffset: Offset16 /// offset from the beginning of MATH table

    init(data: CFData, tableOffset: Offset16) {
        self.data = data
        self.tableOffset = tableOffset
    }
    
    /// Offset to Coverage table, from the beginning of the MathTopAccentAttachment table.
    public func topAccentCoverageOffset() -> Offset16 {
        data.readOffset16(parentOffset: tableOffset, offset: 0)
    }

    /// Number of top accent attachment point values. Must be the same as the number of
    /// glyph IDs referenced in the Coverage table.
    public func topAccentAttachmentCount() -> UInt16 {
        data.readUInt16(parentOffset: tableOffset, offset: 2)
    }
        
    /// Array of MathValueRecords defining top accent attachment points for each covered glyph.
    public func topAccentAttachment(_ index: Int) -> MathValueRecord {
        data.readMathValueRecord(parentOffset: tableOffset, offset: 4 + index * MathValueRecord.byteSize)
    }
    
    public func coverageTable() -> CoverageTable {
        CoverageTable(data: data, tableOffset: tableOffset + topAccentCoverageOffset())
    }

    /// Return top accent attachment for glyphID in design units
    public func getTopAccentAttachment(_ glyphID: UInt16) -> Int32? {
        let coverageTable = self.coverageTable()
        if let coverageIndex = coverageTable.getCoverageIndex(glyphID) {
            let mathValueRecord = topAccentAttachment(coverageIndex)
            let value = data.evalMathValueRecord(parentOffset: tableOffset,
                                                 mathValueRecord: mathValueRecord)
            return value
        }
        return nil
    }
}

public class MathKernInfoTable {
    let data: CFData
    let tableOffset: Offset16
    
    init(data: CFData, tableOffset: Offset16) {
        self.data = data
        self.tableOffset = tableOffset
    }
    
    // MARK: - table fields
    
    /// Offset to Coverage table, from the beginning of the MathKernInfo table.
    public func mathKernCoverageOffset() -> Offset16 {
        data.readOffset16(parentOffset: tableOffset, offset: 0)
    }
    
    /// Number of MathKernInfoRecords. Must be the same as the number of glyph
    /// IDs referenced in the Coverage table.
    public func mathKernCount() -> UInt16 {
        data.readUInt16(parentOffset: tableOffset, offset: 2)
    }
    
    /// Array of MathKernInfoRecords, one for each covered glyph.
    public func mathKernInfoRecords(_ index: Int) -> MathKernInfoRecord {
        data.readMathKernInfoRecord(parentOffset: tableOffset, offset: 4 + index * MathKernInfoRecord.byteSize)
    }
    
    // MARK: - optimization
    
    private func mathKernOffset(index: Int, corner: MathKernCorner) -> Offset16 {
        let offset = 4 + index * MathKernInfoRecord.byteSize + corner.getByteOffset()
        return data.readOffset16(parentOffset: tableOffset, offset: offset)
    }
    
    private func getMathKernOffset(glyphID: UInt16, corner: MathKernCorner) -> Offset16? {
        let coverageTable = self.coverageTable()
        if let coverageIndex = coverageTable.getCoverageIndex(glyphID) {
            return mathKernOffset(index: coverageIndex, corner: corner)
        }
        return nil
    }
    
    // MARK: - query functions
    
    public func coverageTable() -> CoverageTable {
        CoverageTable(data: data, tableOffset: tableOffset + mathKernCoverageOffset())
    }
    
    public func getMathKernInfoRecord(_ glyphID: UInt16) -> MathKernInfoRecord? {
        let coverageTable = self.coverageTable()
        if let coverageIndex = coverageTable.getCoverageIndex(glyphID) {
            return mathKernInfoRecords(coverageIndex)
        }
        return nil
    }
    
    public func getKernValue(glyphID: UInt16, corner: MathKernCorner, height: Int32) -> Int32? {
        if let mathKernOffset = getMathKernOffset(glyphID: glyphID, corner: corner) {
            let mathKernTable = MathKernTable(data: data, tableOffset: self.tableOffset + mathKernOffset)
            return mathKernTable.getKernValue(height: height)
        }
        return nil
    }
}

public class MathKernTable {
    let data: CFData
    let tableOffset: Offset16
    
    init(data: CFData, tableOffset: Offset16) {
        self.data = data
        self.tableOffset = tableOffset
    }
    
    // MARK: - table fields

    /// Number of heights at which the kern value changes.
    public func heightCount() -> UInt16 {
        data.readUInt16(parentOffset: tableOffset, offset: 0)
    }
    
    /// Array of correction heights, in design units, sorted from lowest to highest.
    public func correctionHeight(_ index: Int) -> MathValueRecord {
        data.readMathValueRecord(parentOffset: tableOffset, offset: 2 + index * MathValueRecord.byteSize)
    }
    
    /// Array of kerning values for different height ranges.
    /// Negative values are used to move glyphs closer to each other.
    public func kernValues(_ index: Int) -> MathValueRecord {
        let offset = 2 + Int(heightCount()) * MathValueRecord.byteSize + index * MathValueRecord.byteSize
        return data.readMathValueRecord(parentOffset: tableOffset, offset: offset)
    }
    
    // MARK: - query functions
    
    /// Return the correction height at the given index in design units
    public func getCorrectionHeight(_ index: Int) -> Int32 {
        let mathValueRecord = self.correctionHeight(index)
        let value = data.evalMathValueRecord(parentOffset: tableOffset, mathValueRecord: mathValueRecord)
        return value
    }
    
    /// Return the kern value at the given index in design units
    public func getKernValue(_ index: Int) -> Int32 {
        let mathValueRecord = self.kernValues(index)
        let value = data.evalMathValueRecord(parentOffset: tableOffset, mathValueRecord: mathValueRecord)
        return value
    }
    
    /// Return the kern value for the given height in design units
    public func getKernValue(height: Int32) -> Int32 {
        if let index = upper_bound(height: height) {
            return self.getKernValue(index)
        }
        return self.getKernValue(0)
    }
    
    // MARK: - helper functions

    /// Return the index of the first element not less than the given height.
    /// We borrow the implementation of `std::lower_bound()` from C++ STL.
    private func lower_bound(height: Int32) -> Int? {
        var count = Int(self.heightCount())
        var first = 0
        let last = count
        
        while (count > 0) {
            var it = first
            let step = count / 2
            it += step
            
            if (getCorrectionHeight(it) < height) {
                it += 1
                first = it
                count -= step + 1
            }
            else {
                count = step
            }
        }
        return first == last ? nil : first
    }
    
    /// Return the index of the first element greater than the given height.
    /// We borrow the implementation of `std::upper_bound()` from C++ STL.
    private func upper_bound(height: Int32) -> Int? {
        var count = Int(self.heightCount())
        var first = 0
        let last = count
        
        while (count > 0) {
            var it = first
            let step = count / 2
            it += step
            
            if !(height < getCorrectionHeight(it)) {
                it += 1
                first = it
                count -= step + 1
            }
            else {
                count = step
            }
        }
        
        if first != last {
            return first
        }
        else if height < getCorrectionHeight(0) {
            return nil
        }
        else {
            return last
        }
    }
}

public enum MathKernCorner : Int {
    case TopRight = 0
    case TopLeft = 1
    case BottomRight = 2
    case BottomLeft = 3
    
    func getByteOffset() -> Int {
        rawValue * 2
    }
}

public struct MathKernInfoRecord {
    static let byteSize = 8
    
    /// Offset to MathKern table for top right corner, from the beginning
    /// of the MathKernInfo table. May be NULL.
    public let topRightMathKernOffset: Offset16
    
    /// Offset to MathKern table for the top left corner, from the beginning
    /// of the MathKernInfo table. May be NULL.
    public let topLeftMathKernOffset: Offset16
    
    /// Offset to MathKern table for bottom right corner, from the beginning
    /// of the MathKernInfo table. May be NULL.
    public let bottomRightMathKernOffset: Offset16
    
    /// Offset to MathKern table for bottom left corner, from the beginning
    /// of the MathKernInfo table. May be NULL.
    public let bottomLeftMathKernOffset: Offset16
    
    init() {
        self.init(topRightMathKernOffset: 0,
                  topLeftMathKernOffset: 0,
                  bottomRightMathKernOffset: 0,
                  bottomLeftMathKernOffset: 0)
    }
    
    init(topRightMathKernOffset: Offset16,
         topLeftMathKernOffset: Offset16,
         bottomRightMathKernOffset: Offset16,
         bottomLeftMathKernOffset: Offset16) {
        self.topRightMathKernOffset = topRightMathKernOffset
        self.topLeftMathKernOffset = topLeftMathKernOffset
        self.bottomRightMathKernOffset = bottomRightMathKernOffset
        self.bottomLeftMathKernOffset = bottomLeftMathKernOffset
    }
    
    func getMathKernOffset(corner: MathKernCorner) -> Offset16 {
        switch corner {
        case .TopRight:
            return topRightMathKernOffset
        case .TopLeft:
            return topLeftMathKernOffset
        case .BottomRight:
            return bottomRightMathKernOffset
        case .BottomLeft:
            return bottomLeftMathKernOffset
        }
    }
}