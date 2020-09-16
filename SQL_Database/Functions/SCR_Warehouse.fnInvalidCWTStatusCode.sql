USE [CancerReporting]
GO
/****** Object:  UserDefinedFunction [SCR_Warehouse].[fnInvalidCWTStatusCode]    Script Date: 03/09/2020 23:44:42 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



/******************************************************** © Copyright & Licensing ****************************************************************
© 2020 Perspicacity Ltd & Brighton & Sussex University Hospitals NHS Trust

Original Work Created Date:	23/04/2020
Original Work Created By:	Lawrence Simpson / Perspicacity Ltd (Matthew Bishop)
Original Work Contact:		07545 878906
Original Work Contact:		matthew.bishop@perspicacityltd.co.uk
Description:				Calculate the CWT status code for records against the 62 day pathway
**************************************************************************************************************************************************/

-- Test me
-- 

CREATE FUNCTION [SCR_Warehouse].[fnInvalidCWTStatusCode]
(
	@cwtFlagValue int
)

RETURNS int
AS
BEGIN
	
	-- Uncategorised
	IF @cwtFlagValue = 0
	RETURN	35 -- Closed / Excluded
	IF @cwtFlagValue = 1
	RETURN	36 -- Open
	IF @cwtFlagValue = 2
	RETURN	37 -- Reportable
	IF @cwtFlagValue = 4
	RETURN	38 -- Not applicable
	IF @cwtFlagValue = 5
	RETURN	39 -- Error!

	-- Catch all for any records not yet categorised
	RETURN 34 -- Error!

END
GO
