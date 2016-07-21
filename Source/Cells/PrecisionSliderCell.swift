// MIT license. Copyright (c) 2016 SwiftyFORM. All rights reserved.
import UIKit

public class PrecisionSliderCellModel {
	var title: String?
	var value: Double = 0.0
	var minimumValue: Double = 0.0
	var maximumValue: Double = 1.0
	
	var valueDidChange: Double -> Void = { (value: Double) in
		SwiftyFormLog("value \(value)")
	}
	
	typealias ExpandCollapseAction = (indexPath: NSIndexPath, tableView: UITableView) -> Void
	var expandCollapseAction: ExpandCollapseAction?
}


public class PrecisionSliderCell: UITableViewCell, CellHeightProvider, SelectRowDelegate {
	weak var expandedCell: PrecisionSliderCellExpanded?
	public let model: PrecisionSliderCellModel

	public init(model: PrecisionSliderCellModel) {
		self.model = model
		super.init(style: .Value1, reuseIdentifier: nil)
		selectionStyle = .None
		clipsToBounds = true
		textLabel?.text = model.title
		reloadValueLabel()
	}
	
	public required init(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	public func form_cellHeight(indexPath: NSIndexPath, tableView: UITableView) -> CGFloat {
		return 60
	}
	
	public func form_didSelectRow(indexPath: NSIndexPath, tableView: UITableView) {
		model.expandCollapseAction?(indexPath: indexPath, tableView: tableView)
	}
	
	func reloadValueLabel() {
		detailTextLabel?.text = String(format: "%.3f", model.value)
	}
	
	func sliderDidChange(newValue: Double?) {
		let newValueOrZero = newValue ?? 0.0
		if model.value == newValue {
			return
		}
		model.value = newValueOrZero
		model.valueDidChange(newValueOrZero)
		reloadValueLabel()
	}
}

extension PrecisionSliderCellModel {
	func sliderViewModel(sliderWidthInPixels sliderWidthInPixels: Double) -> PrecisionSlider_InnerModel {
		let instance = PrecisionSlider_InnerModel()
		instance.minimumValue = minimumValue
		instance.maximumValue = maximumValue
		
		let rangeLength = maximumValue - minimumValue
		if sliderWidthInPixels > 10 && rangeLength > 0.001 {
			instance.scale = sliderWidthInPixels / rangeLength
		} else {
			instance.scale = 10
		}
		
		let count = Int(floor(maximumValue) - ceil(minimumValue))
		if count < 0 {
			//print("partial item that doesn't cross a integer boundary. maximumValue=\(maximumValue)  minimumValue=\(minimumValue)")
			instance.numberOfFullItems = 0
			instance.hasOnePartialItem = true
			instance.sizeOfOnePartialItem = maximumValue - minimumValue
			instance.hasPartialItemBefore = false
			instance.sizeOfPartialItemBefore = 0
			instance.hasPartialItemAfter = false
			instance.sizeOfPartialItemAfter = 0
			return instance
		}
		instance.numberOfFullItems = count

		let sizeBefore = ceil(minimumValue) - minimumValue
		//print("size before: \(sizeBefore)    \(minimumValue)")
		if sizeBefore > 0.0000001 {
			//print("partial item before. size: \(sizeBefore)   minimumValue: \(minimumValue)")
			instance.hasPartialItemBefore = true
			instance.sizeOfPartialItemBefore = sizeBefore
		}

		let sizeAfter = maximumValue - floor(maximumValue)
		//print("size after: \(sizeAfter)    \(maximumValue)")
		if sizeAfter > 0.0000001 {
			//print("partial item after. size: \(sizeAfter)   minimumValue: \(maximumValue)")
			instance.hasPartialItemAfter = true
			instance.sizeOfPartialItemAfter = sizeAfter
		}
		
		return instance
	}
}

public class PrecisionSliderCellExpanded: UITableViewCell, CellHeightProvider {
	struct Constants {
		static let insetForInitialZoom: CGFloat = 10.0
	}
	

	weak var collapsedCell: PrecisionSliderCell?

	public func form_cellHeight(indexPath: NSIndexPath, tableView: UITableView) -> CGFloat {
		return PrecisionSlider_InnerModel.height
	}
	
	func sliderDidChange() {
		collapsedCell?.sliderDidChange(slider.value)
	}
	
	lazy var slider: PrecisionSlider = {
		let instance = PrecisionSlider()
		instance.valueDidChange = nil
		return instance
	}()
	
	public init() {
		super.init(style: .Default, reuseIdentifier: nil)
		addSubview(slider)
	}
	
	required public init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	public override func layoutSubviews() {
		super.layoutSubviews()
		slider.frame = bounds
		
		let tinyDelay = dispatch_time(DISPATCH_TIME_NOW, Int64(0.001 * Float(NSEC_PER_SEC)))
		dispatch_after(tinyDelay, dispatch_get_main_queue()) {
			self.assignInitialValue()
		}
	}
	
	func assignInitialValue() {
		if slider.valueDidChange != nil {
			return
		}
		guard let model = collapsedCell?.model else {
			return
		}
		
		let sliderWidth = slider.bounds.width - Constants.insetForInitialZoom
		let sliderViewModel = model.sliderViewModel(sliderWidthInPixels: Double(sliderWidth))
		//print("sliderViewModel \(sliderViewModel.debugDescription)")
		slider.model = sliderViewModel
		slider.layout.model = sliderViewModel
		slider.setNeedsLayout()
		slider.setNeedsDisplay()
		slider.collectionView.reloadData()
		
		/*
		First we scroll to the right offset
		Next establish two way binding
		*/
		slider.setValue(model.value, animated: false)

		slider.valueDidChange = { [weak self] in
			self?.sliderDidChange()
		}
	}
	
	func setValueWithoutSync(value: Double, animated: Bool) {
		SwiftyFormLog("set value \(value), animated \(animated)")
		slider.setValue(value, animated: animated)
	}
}
