# Function to remove and update the saucer package when the the correct directory
# Needs more work to handle errors and shit.
remove_and_update_saucer = function()
{
    status = system("R -e \"require('rutilities'); remove.packages('saucer'); exit()\"", intern = TRUE)
    status = attr(status, "status")
    if(length(status) > 0)
    {
        if(status == 1)
        {
            stop("Exeuction error remove saucer package failed")
        }
    }
    status = system("R -e \"require('rutilities'); update_package('saucer'); exit()\"", intern = TRUE)
    status = attr(status, "status")
    if(length(status) > 0)
    {
        if(status == 1)
        {
            stop("Exeuction error update saucer package failed")
        }
    }
    return()
}



