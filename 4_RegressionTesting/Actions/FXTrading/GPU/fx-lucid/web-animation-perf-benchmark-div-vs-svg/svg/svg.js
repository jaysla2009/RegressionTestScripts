//to not pollute global space
var svg = {};
svg.dataFrom = [];
svg.dataTo = [];
svg.numLayers = 200;
svg.updateRate = 300;
svg.dataFlag = false;
svg.horizontalCount = 40;
svg.layerWidth = 40;
svg.layerHeight = 100;

//Note data can be only between 0 and 100
svg.initializeData = function initializeData(){
    for (var i = 0; i < svg.numLayers; i++) {
        if (i % 2 === 0) {
            svg.dataFrom.push({index: i, data: 100});
            svg.dataTo.push({index: i, data: 0});
        } else {
            svg.dataFrom.push({index: i, data: 0});
            svg.dataTo.push({index: i, data: 100});
        }
    }
};

svg.rowCache = {};
svg.getRow = function(i){
    if(svg.rowCache[i] !== undefined) return svg.rowCache[i];
    return svg.rowCache[i] = Math.floor(i / svg.horizontalCount);
};

svg.chartWidth = (svg.horizontalCount * svg.layerWidth) + (svg.horizontalCount * 2);
svg.chartHeight = (svg.numLayers / svg.horizontalCount) * svg.layerHeight;
svg.chart = d3.select(".chart-auto")
                .attr('width', svg.chartWidth)
                .attr('height', svg.chartHeight);

svg.getX = function(i){
    return ((svg.layerWidth * i) + (2*i)+1) - (svg.getRow(i) * svg.chartWidth);
};

svg.getY = function(d, i){
    var heightAdd = svg.getRow(i) * svg.layerHeight;
    return (svg.layerHeight - d.data) + heightAdd;
};

svg.updateChart = function updateChart() {
    var data;
    if (svg.dataFlag) {
        svg.dataFlag = false;
        data = svg.dataFrom;
    } else {
        svg.dataFlag = true;
        data = svg.dataTo;
    }

    var layer = svg.chart.selectAll("g")
        .data(data);

    layer.exit().remove();

    layer.enter().append("g")
        .each(function(d) {
            d3.select(this)
                .append('rect')
                .attr('width', svg.layerWidth)
                .style('fill', 'blue');
        });

    layer
        .transition()
        .attr("transform", function(d, i) { return "translate(" + svg.getX(i) + "," + svg.getY(d, i) + ")"; });

    layer.select('rect')
        .transition()
        .attr('height', function(d) {
                      return d.data;
                  });
};

svg.initializeData();

setInterval(function() {
    svg.updateChart();
}, svg.updateRate);