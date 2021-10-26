mkdir -p ./sample_customer/{incoming/{amex/{bintable/{in_process,processed,rejected},clearing/{in_process,processed,rejected},epa/{in_process,processed,rejected}},applications/acq,dci/{bintable/{in_process,processed,rejected},clearing/{in_process,processed,rejected},epa/{in_process,processed,rejected}},finservices/bacs/report/{in_process,processed,rejected},mc/{clearing/{in_process,processed,rejected},currency/{in_process,processed,rejected},dictionary/{in_process,processed,rejected},interchange/{in_process,processed,rejected}},visa/{bintable/{in_process,processed,rejected},clearing/{in_process,processed,rejected},interchange/{in_process,processed,rejected}},POSTING},outgoing/{amex/clearing,dci/clearing,invoices,mc/clearing,merchantportal,reports,statements_and_invoices,svfe/{merchant,terminal},svfm/{merchants,terminals},visa/clearing}}

exit 0



mkdir -p ./sample_customer/
{
	incoming/
	{
		amex/
		{
			bintable/{in_process,processed,rejected},
			clearing/{in_process,processed,rejected},
			epa/{in_process,processed,rejected}
		},
		applications/acq,
		dci/
		{
			bintable/{in_process,processed,rejected},
			clearing/{in_process,processed,rejected},
			epa/{in_process,processed,rejected}
		},
			finservices/bacs/report/{in_process,processed,rejected},
		mc/
		{
			clearing/{in_process,processed,rejected},
			currency/{in_process,processed,rejected},
			dictionary/{in_process,processed,rejected},
			interchange/{in_process,processed,rejected}
		},
		visa/
		{
			bintable/{in_process,processed,rejected},
			clearing/{in_process,processed,rejected},
			interchange/{in_process,processed,rejected}
		},
		POSTING
	},
	outgoing/
	{
		amex/clearing,
		dci/clearing,
		invoices,
		mc/clearing,
		merchantportal,
		reports,
		statements_and_invoices,
		svfe/
			{
			merchant,	
			terminal
			},
		svfm/
			{
			merchants,
			terminals
			},
		visa/clearing
	}
}
