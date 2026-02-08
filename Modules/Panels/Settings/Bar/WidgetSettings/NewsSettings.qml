import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

ColumnLayout {
  id: root
  spacing: Style.marginM

  // Provided by the dialog loader
  property var widgetData: null
  property var widgetMetadata: null

  signal settingsChanged(var settings)

  // Local state
  property string displayModeValue: widgetData.displayMode !== undefined ? widgetData.displayMode: widgetMetadata.displayMode
  property string apiKeyValue: widgetData.apiKey !== undefined ? widgetData.apiKey : widgetMetadata.apiKey
  property string categoryValue: widgetData?.category !== undefined ? widgetData.category : widgetMetadata.category 
  property int refreshIntervalValue: widgetData?.refreshInterval !== undefined ? widgetData.refreshInterval : widgetMetadata.refreshInterval
  property int maxHeadlinesValue: widgetData?.maxHeadlines !== undefined ? widgetData.maxHeadlines : widgetMetadata.maxHeadlines
  property int changeNewsInterval: widgetData?.changeNewsInterval !== undefined ? widgetData.changeNewsInterval : widgetMetadata.changeNewsInterval
  property int rollingSpeed: widgetData?.rollingSpeed !== undefined ? widgetData.rollingSpeed : widgetMetadata.rollingSpeed
  property int widgetWidth: widgetData?.widgetWidth !== undefined ? widgetData.widgetWidth : widgetMetadata.widgetWidth

  // Called by the dialog's Apply button
  function saveSettings() {
    var settings = Object.assign({}, widgetData || {});
    settings.displayMode = displayModeValue;
    settings.apiKey = apiKeyValue;
    settings.category = categoryValue
    settings.refreshInterval = refreshIntervalValue
    settings.widgetWidth = widgetWidth 
    settings.maxHeadlines = maxHeadlinesValue
    settings.changeNewsInterval = changeNewsInterval
    settings.rollingSpeed = rollingSpeed
    return settings;
  }


  NComboBox {
    label: I18n.tr("common.display-mode")
    description: I18n.tr("bar.volume.display-mode-description")
    minimumWidth: 200
    model: [
      {
        "key": "onhover",
        "name": I18n.tr("display-modes.on-hover")
      },
      {
        "key": "alwaysShow",
        "name": I18n.tr("display-modes.always-show")
      },
      {
        "key": "alwaysHide",
        "name": I18n.tr("display-modes.always-hide")
      }
    ]
    currentKey: displayModeValue 
    onSelected: key => {
      displayModeValue = key;
      settingsChanged(saveSettings());
    }
  }

  // API Key Configuration Section

  NTextInput {
    label: "API Key"
    description: "NewsAPI.org API Key"
    text: apiKeyValue
    onTextChanged: apiKeyValue = text
    onEditingFinished: settingsChanged(saveSettings())
  }

  NTextInput {
    label: "Category"
    description: "NewsAPI.org Category"
    text: categoryValue
    onTextChanged: categoryValue = text
    onEditingFinished: settingsChanged(saveSettings())
  }

  NSpinBox {
    label: "Refresh Interval"
    description: "Interval in minutes between fetching news"
    from: 1
    to: 60
    value: refreshIntervalValue
    onValueChanged: {
      refreshIntervalValue = value;
      settingsChanged(saveSettings())
    }
  }
  
  NSpinBox {
    label: "Widget Width"
    description: "The width of the widget in pixels"
    from: 60
    to: 600
    value: widgetWidth 
    onValueChanged: {
      widgetWidth = value;
      settingsChanged(saveSettings())
    }
  }
  
  NSpinBox {
    label: "Max Headlines"
    description: "Maximum number of headlines to load"
    from: 2
    to: 9
    value: maxHeadlinesValue 
    onValueChanged: {
      maxHeadlinesValue = value;
      settingsChanged(saveSettings())
    }
  }

  NSpinBox {
    label: "Change News Interval"
    description: "Interval in seconds before News to change"
    from: 5
    to: 50
    value: changeNewsInterval 
    onValueChanged: {
      changeNewsInterval = value;
      settingsChanged(saveSettings())
    }
  }
  
  NSpinBox {
    label: "Rolling Speed"
    description: "Time in ms per pixel"
    from: 10
    to: 100
    value: rollingSpeed
    onValueChanged: {
      rollingSpeed = value;
      settingsChanged(saveSettings())
    }
  }
}
