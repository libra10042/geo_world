import { useEffect, useState } from 'react'
import Feature from 'ol/Feature.js';
import Map from 'ol/Map.js';
import View from 'ol/View.js';
import {getWidth} from 'ol/extent.js';
import LineString from 'ol/geom/LineString.js';
import TileLayer from 'ol/layer/Tile.js';
import VectorLayer from 'ol/layer/Vector.js';
import {getVectorContext} from 'ol/render.js';
import StadiaMaps from 'ol/source/StadiaMaps.js';
import VectorSource from 'ol/source/Vector.js';
import Stroke from 'ol/style/Stroke.js';
import Style from 'ol/style/Style.js';
import { Arc } from 'arc';  // npm 설치한 arc 불러오기


function App() {
 useEffect(() => {

  const tileLayer = new TileLayer({
    source: new OSM(),
  });

  const map = new Map({
    layers: [tileLayer],
    target: 'map',
    view: new View({
      center: [-11000000, 4600000],
      zoom: 2,
    }),
  });

  const style = new Style({
    stroke: new Stroke({
      color: '#EAE911',
      width: 2,
    }),
  });

  const baseUrl = import.meta.env.BASE_URL;

  const flightsSource = new VectorSource({
    attributions:
      'Flight data by ' +
      '<a href="https://openflights.org/data.html">OpenFlights</a>,',
    loader: function () {
      const url = `${baseUrl}data/flights.json`;
      fetch(url)
        .then(function (response) {
          return response.json();
        })
        .then(function (json) {
          const flightsData = json.flights;
          for (let i = 0; i < flightsData.length; i++) {
            const flight = flightsData[i];
            const from = flight[0];
            const to = flight[1];

            // create an arc circle between the two locations
            const arcGenerator = new arc.GreatCircle(
              {x: from[1], y: from[0]},
              {x: to[1], y: to[0]},
            );

            const arcLine = arcGenerator.Arc(100, {offset: 10});
            // paths which cross the -180°/+180° meridian are split
            // into two sections which will be animated sequentially
            const features = [];
            arcLine.geometries.forEach(function (geometry) {
              const line = new LineString(geometry.coords);
              line.transform('EPSG:4326', 'EPSG:3857');

              features.push(
                new Feature({
                  geometry: line,
                  finished: false,
                }),
              );
            });
            // add the features with a delay so that the animation
            // for all features does not start at the same time
            addLater(features, i * 50);
          }
          tileLayer.on('postrender', animateFlights);
        });
    },
  });

  const flightsLayer = new VectorLayer({
    source: flightsSource,
    style: function (feature) {
      // if the animation is still active for a feature, do not
      // render the feature with the layer style
      if (feature.get('finished')) {
        return style;
      }
      return null;
    },
  });

  map.addLayer(flightsLayer);

  const pointsPerMs = 0.02;
  function animateFlights(event) {
    const vectorContext = getVectorContext(event);
    const frameState = event.frameState;
    vectorContext.setStyle(style);

    const features = flightsSource.getFeatures();
    for (let i = 0; i < features.length; i++) {
      const feature = features[i];
      if (!feature.get('finished')) {
        // only draw the lines for which the animation has not finished yet
        const coords = feature.getGeometry().getCoordinates();
        const elapsedTime = frameState.time - feature.get('start');
        if (elapsedTime >= 0) {
          const elapsedPoints = elapsedTime * pointsPerMs;

          if (elapsedPoints >= coords.length) {
            feature.set('finished', true);
          }

          const maxIndex = Math.min(elapsedPoints, coords.length);
          const currentLine = new LineString(coords.slice(0, maxIndex));

          // animation is needed in the current and nearest adjacent wrapped world
          const worldWidth = getWidth(map.getView().getProjection().getExtent());
          const offset = Math.floor(map.getView().getCenter()[0] / worldWidth);

          // directly draw the lines with the vector context
          currentLine.translate(offset * worldWidth, 0);
          vectorContext.drawGeometry(currentLine);
          currentLine.translate(worldWidth, 0);
          vectorContext.drawGeometry(currentLine);
        }
      }
    }
    // tell OpenLayers to continue the animation
    map.render();
  }

  function addLater(features, timeout) {
    window.setTimeout(function () {
      let start = Date.now();
      features.forEach(function (feature) {
        feature.set('start', start);
        flightsSource.addFeature(feature);
        const duration =
          (feature.getGeometry().getCoordinates().length - 1) / pointsPerMs;
        start += duration;
      });
    }, timeout);
  }

 }, [])
  return (
    <div id="map"></div>
  )
}

export default App