$(document).ready(function()
{
  $('#add_form').submit(function()
  {
    var myForm = $( this ).serialize(); 

    $.post( "/cgi-bin/Dispatcher.pl", myForm,
      function() 
      {
        var no_duplicating = true;
        var group_id = $('#add_form input#input_group_id').val();
        $('table > tbody  > tr > td#row_group_id').each(function()
        { 
          if( $(this).html() === group_id )
          {
            $("div#ok_message").addClass("alert alert-danger");
            $("div#ok_message").html("<strong>Duplicating input!</strong> Try another ID...");
            no_duplicating = false;
          }
        });

        if ( group_id === "" ) 
        {  
          $("div#ok_message").addClass("alert alert-danger");
          $("div#ok_message").html("<strong>No id in form!</strong> Just enter ID...");
        }
        else if (no_duplicating)
        {
          $("div#ok_message").addClass("alert alert-success");
          $("div#ok_message").html("Group was added!");
          $("div#db_result").load(location.href + " div#db_result"); 
        }
      });

    return false;
  });
});
