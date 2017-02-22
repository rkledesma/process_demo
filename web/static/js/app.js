const $ = require('jquery');
window.jQuery = $;
import socket from './socket';

const work_id = $(".work_id").text();
let currentStatus = $(".work_status").text();

if (work_id.length > 0) {
  const workOutput = $("pre.work_output");
  listen(workOutput);
  toggleAbortBtn(currentStatus);
}

function listen(workOutput) {
  const topic = "work:" + work_id;
  const channel = socket.channel(topic, {});
  let currentStatus = "";
  const statusElement = $("td.work_status");

  channel.join()
    .receive("ok", data => {
      console.log("joined work:" + work_id);
    })
    .receive("error", resp => {
      //console.log("Unable to join topic", topic);
  });

  channel.on("change", work => {
    workOutput.html(work.data);

    if (currentStatus != work.status) {
      currentStatus = work.status;
      statusElement.text(currentStatus);
      toggleAbortBtn(currentStatus);
      $("td.work_status").text(currentStatus);
    }
  });
}

function toggleAbortBtn(status) {
  const abortBtn = $('.form__abort');
  if (status == "running") {
    show(abortBtn);
  }
  else {
    hide(abortBtn);
  }
}

$('.btn__submit_abort').click(function() {
  return submitAbortForm($(".form__abort"));
});

//abort a work request via ajax POST in order to stay on the same page/channel
function submitAbortForm (form) {
  const form_data = form.serialize();
  $.ajax({
    type: "POST",
    url: "/works/" + work_id + "/abort",
    data: form_data,
    success: function(data) {
      console.log("work Aborted");
    },
    error: function(jqxhr) {
      console.log(jqxhr.responseText);
    }
  });
  return false;
};


function isRunning() {
  return $(".work_status").text() == "running";
}

function show(element) {
  element.toggleClass('hidden', false);
};

function hide(element) {
  element.toggleClass('hidden', true);
};
