// Leaderboard Page
$('table.dynatable').dynatable({
  readers: {
    rank: function(el, record) {
      return Number(el.innerHTML) || 0;
    }
    ,
    score: function(el, record) {
      if($.trim(el.innerHTML) == '') {
        return el.innerHTML;
      } else {
        return Number(el.innerHTML.replace(/,/g,""));
      }
    }
  },
  writers: {
    score: function(record) {
      return record['score'].toString().replace(/\B(?=(\d{3})+(?!\d))/g, ",");
    }
  }
});

$('table.nopage_dynatable').dynatable({
  features: {
        paginate: false,
        sort: true
      },
  readers: {
    rank: function(el, record) {
      return Number(el.innerHTML) || 0;
    },
    score: function(el, record) {
      if($.trim(el.innerHTML) == '') {
        return el.innerHTML;
      } else {
        return Number(el.innerHTML.replace(/,/g,""));
      }
    },
    totalScore: function(el, record) {
      return Number(el.innerHTML.replace(/,/g,"")) || 0;
    },
    badgeScore: function(el, record) {
      return Number(el.innerHTML.replace(/,/g,"")) || 0;
    },
    rawScore: function(el, record) {
      return Number(el.innerHTML.replace(/,/g,"")) || 0;
    },
    multipliedScore: function(el, record) {
      return Number(el.innerHTML.replace(/,/g,"")) || 0;
    },
    meanScore: function(el, record) {
      return Number(el.innerHTML.replace(/,/g,"")) || 0;
    },
    challengeScore: function(el, record) {
      return Number(el.innerHTML.replace(/,/g,"")) || 0;
    },
    students: function(el, record) {
      return Number(el.innerHTML.replace(/,/g,"")) || 0;
    },
    badges: function(el, record) {
      return Number(el.innerHTML.replace(/,/g,"")) || 0;
    },
    min: function(el, record) {
      return Number(el.innerHTML.replace(/,/g,"")) || 0;
    },
    max: function(el, record) {
      return Number(el.innerHTML.replace(/,/g,"")) || 0;
    },
    median: function(el, record) {
      return Number(el.innerHTML.replace(/,/g,"")) || 0;
    },
    ave: function(el, record) {
      return Number(el.innerHTML.replace(/,/g,"")) || 0;
    },
    aveEarned: function(el, record) {
      return Number(el.innerHTML.replace(/,/g,"")) || 0;
    },
    submissions: function(el, record) {
      return Number(el.innerHTML.replace(/,/g,"")) || 0;
    },
    grades: function(el, record) {
      return Number(el.innerHTML.replace(/,/g,"")) || 0;
    }
  },
  writers: {
    score: function(record) {
      return record['score'].toString().replace(/\B(?=(\d{3})+(?!\d))/g, ",");
    }
  }
});

$('table.nosearch_dynatable').dynatable({
  features: {
        search: false,
        sort: true
      },
  readers: {
    rank: function(el, record) {
      return Number(el.innerHTML) || 0;
    },
    score: function(el, record) {
      if($.trim(el.innerHTML) == '') {
        return el.innerHTML;
      } else {
        return Number(el.innerHTML.replace(/,/g,""));
      }
    }
  },
  writers: {
    score: function(record) {
      return record['score'].toString().replace(/\B(?=(\d{3})+(?!\d))/g, ",");
    }
  }
});

$('table.nopage_orsearch_dynatable').dynatable({
  features: {
    search: false,
    paginate: false,
    sort: true
  }
});

$('table.nofeatures_default_last_name_dynatable').dynatable({
  features: {
    paginate: false,
    search: false,
    recordCount: false,
    sort: true
  },
  dataset: {
    sorts: { 'lastName': 1 }
  },
  readers: {
    dueDate: function(el, record) {
      record.parsedDate = Date.parse(el.innerHTML);
      return el.innerHTML;
    },
    points: function(el, record) {
      return Number(el.innerHTML.replace(/,/g,""));
    },
    maxValue: function(el, record) {
      return Number(el.innerHTML.replace(/,/g,""));
    },
    totalBadgeScore: function(el, record) {
      return Number(el.innerHTML.replace(/,/g,""));
    },
    badgeCount: function(el, record) {
      return Number(el.innerHTML.replace()) || 0;
    },
    score: function(el, record) {
      if($.trim(el.innerHTML) == '') {
        return el.innerHTML;
      } else {
        return Number(el.innerHTML.replace(/,/g,""));
      }
    },
    rawScore: function(el, record) {
      return Number(el.innerHTML.replace(/,/g,""));
    },
    multipliedScore: function(el, record) {
      return Number(el.innerHTML.replace(/,/g,"")) || 0;
    }
  },
  writers: {
    score: function(record) {
      return record['score'].toString().replace(/\B(?=(\d{3})+(?!\d))/g, ",");
    }
  }
});

$('table.nofeatures_default_name_dynatable').dynatable({

  features: {
        paginate: false,
        search: false,
        recordCount: false,
        sort: true
      },
  dataset: {
      sorts: { 'name': 1 }
  },
  readers: {
      dueDate: function(el, record) {
        record.parsedDate = Date.parse(el.innerHTML);
        return el.innerHTML;
      },
      points: function(el, record) {
        return Number(el.innerHTML.replace(/,/g,"")) || 0;
      },
      maxValue: function(el, record) {
        return Number(el.innerHTML.replace(/,/g,"")) || 0;
      }
    }
});

$('table.nofeatures_default_score_dynatable').dynatable({
  features: {
        paginate: false,
        search: false,
        recordCount: false,
        sort: true
      },
  dataset: {
      sorts: { 'score': -1 }
  },
  readers: {
      score: function(el, record) {
        if($.trim(el.innerHTML) == '') {
          return el.innerHTML;
        } else {
          return Number(el.innerHTML.replace(/,/g,""));
        }
      },
      dueDate: function(el, record) {
        record.parsedDate = Date.parse(el.innerHTML);
        return el.innerHTML;
      },
      points: function(el, record) {
        return Number(el.innerHTML.replace(/,/g,"")) || 0;
      },
      maxValue: function(el, record) {
        return Number(el.innerHTML.replace(/,/g,"")) || 0;
      },
      rank: function(el, record) {
        return Number(el.innerHTML.replace(/,/g,"")) || 0;
      },
      meanStudentScore: function(el, record) {
        return Number(el.innerHTML.replace(/,/g,"")) || 0;
      },
      challengeScore: function(el, record) {
        return Number(el.innerHTML.replace(/,/g,"")) || 0;
      },
      badges: function(el, record) {
        return Number(el.innerHTML.replace(/,/g,"")) || 0;
      },
      students: function(el, record) {
        return Number(el.innerHTML.replace(/,/g,"")) || 0;
      }
    },
    writers: {
      score: function(record) {
        return record['score'].toString().replace(/\B(?=(\d{3})+(?!\d))/g, ",");
      }
    }
});

$('table.nofeatures_default_desc_score_dynatable').dynatable({

  features: {
        paginate: false,
        search: false,
        recordCount: false,
        sort: true
      },
  dataset: {
      sorts: { 'score': -1 }
  }
});

$('table.nofeatures_dynatable').dynatable({

  features: {
        paginate: false,
        search: false,
        recordCount: false,
        sort: true
      },
  readers: {
      dueDate: function(el, record) {
        record.parsedDate = Date.parse(el.innerHTML);
        return el.innerHTML;
      },
      points: function(el, record) {
        return Number(el.innerHTML.replace(/,/g,"")) || 0;
      },
      maxValue: function(el, record) {
        return Number(el.innerHTML.replace(/,/g,"")) || 0;
      },
      lowRange: function(el, record) {
        return Number(el.innerHTML.replace(/,/g,"")) || 0;
      },
      highRange: function(el, record) {
        return Number(el.innerHTML.replace(/,/g,"")) || 0;
      }
    }
});


$('table.nofeatures_default_due_date_dynatable').dynatable({
  features: {
    paginate: false,
    search: false,
    recordCount: false,
    sort: true
  },
  dataset: {
    sorts: { 'dueDate': 1 }
  },
  readers: {
    dueDate: function(el, record) {
      record.parsedDate = Date.parse(el.innerHTML);
      return el.innerHTML;
    },
    points: function(el, record) {
      return Number(el.innerHTML.replace(/,/g,"")) || 0;
    },
    maxValue: function(el, record) {
      return Number(el.innerHTML.replace(/,/g,"")) || 0;
    }
  }
});

$('table.nofeatures_default_rank_dynatable').dynatable({
  features: {
    paginate: false,
    search: false,
    recordCount: false,
    sort: true
  },
  dataset: {
    sorts: { 'rank': 1 }
  },
  readers: {
    rank: function(el, record) {
      return Number(el.innerHTML) || 0;
    },
    score: function(el, record) {
      if($.trim(el.innerHTML) == '') {
        return el.innerHTML;
      } else {
        return Number(el.innerHTML.replace(/,/g,""));
      }
    },
    badgeCount: function(el, record) {
      return Number(el.innerHTML.replace(/,/g,""));
    }
  },
  writers: {
    score: function(record) {
      return record['score'].toString().replace(/\B(?=(\d{3})+(?!\d))/g, ",");
    }
  }
});

$('table.paginate_default_last_name_dynatable').dynatable({

 features: {
        sort: true
      },
  dataset: {
      sorts: { 'lastName': 1 },
      perPageDefault: 25,
      perPageOptions: [25, 50, 100]
  },
  readers: {
      points: function(el, record) {
        return Number(el.innerHTML.replace(",","")) || 0;
      }
    }
});
