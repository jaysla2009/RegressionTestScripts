//to not pollute global space
var div = {};
div.dataFrom = [];
div.dataTo = [];
div.numLayers = 200;
div.updateRate = 300;
div.dataFlag = false;

div.initializeData = function initializeData(){
    for (var i = 0; i < div.numLayers; i++) {
        if (i % 2 === 0) {
            div.dataFrom.push({index: i, data: 100});
            div.dataTo.push({index: i, data: 0});
        } else {
            div.dataFrom.push({index: i, data: 0});
            div.dataTo.push({index: i, data: 100});
        }
    }
};

div.updateChart = function updateChart() {
    var data;
    if (div.dataFlag) {
        div.dataFlag = false;
        data = div.dataFrom;
    } else {
        div.dataFlag = true;
        data = div.dataTo;
    }

    var layer = d3.select('.chart').selectAll('.layer-container')
        .data(data);

    layer.exit().remove();

    layer.enter().append('div')
        .classed('layer-container', true)
        .each(function(d) {
                  d3.select(this).append('div')
                      .classed('layer', true)

              });

    layer.select('.layer')
        .transition()
        .style({
                    'height': function(d) {
                        return d.data + 'px';
                    }
                });
};

div.initializeData();

setInterval(function() {
    div.updateChart();
}, div.updateRate);